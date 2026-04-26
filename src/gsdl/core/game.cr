module GSDL
  # Internal state for the engine.
  # Consumers should use Game.* API instead of interacting with this directly.
  module Internal
    @@instance : Game?
    @@draw : Draw?
    @@execution_stack = [] of Scene

    def self.instance : Game
      if game = @@instance
        game
      else
        raise "Failed to get global Game instance. Make sure Game.new has been called."
      end
    end

    def self.instance=(game : Game)
      @@instance = game
    end

    def self.draw : Draw
      if draw = @@draw
        draw
      else
        raise "Failed to get global draw"
      end
    end

    def self.draw=(draw : Draw)
      @@draw = draw
    end

    def self.execution_stack
      @@execution_stack
    end
  end

  def self.ticks
    SDL3.get_ticks
  end

  abstract class Game
    include Loadable
    DefaultBackgroundColor = Color::Black

    def self.instance : Game
      Internal.instance
    end

    def self.width : Int32
      instance.width
    end

    def self.height : Int32
      instance.height
    end

    def self.center_x : Int32
      instance.center_x
    end

    def self.center_y : Int32
      instance.center_y
    end

    def self.title : String
      instance.title
    end

    def self.draw : Draw
      Internal.draw
    end

    def self.quit!
      instance.quit!
    end

    def self.scene
      instance.scene
    end

    def self.camera
      (instance.current_context || instance.scene).camera
    end

    def self.push(scene : Scene, data : SwitchData? = nil)
      instance.push(scene, data)
    end

    def self.pop
      instance.pop
    end

    def self.replace(scene : Scene, data : SwitchData? = nil)
      instance.replace(scene, data)
    end

    def self.switch(scene : Scene, data : SwitchData? = nil)
      instance.switch(scene, data)
    end

    def self.switch_async(scene_class : T.class, data : SwitchData? = nil) forall T
      instance.switch_async(scene_class, data)
    end

    def self.loader
      instance.loader
    end

    def self.paused?
      instance.paused?
    end

    def self.paused=(val : Bool)
      instance.paused = val
    end

    def self.fps
      instance.fps_counter.fps
    end

    @window : SDL3::Window?
    @draw : Draw?
    @loader : Loader?
    @exit : Bool = false
    @title : String?
    @width : Int32?
    @height : Int32?
    @logical_width : Int32 = 0
    @logical_height : Int32 = 0
    @paused : Bool = false
    @scenes : Array(Scene) = [] of Scene
    @fps_counter : FPSCounter = FPSCounter.new

    # If nil, the frame rate is uncapped (limited only by vsync if enabled).
    # If set to an Integer (e.g., 60), the game loop will delay to match this FPS.
    property target_fps : Int32? = nil

    # Enable or disable performance monitoring and metric collection.
    property performance_monitoring_enabled : Bool = false

    # Logical resolution properties
    property logical_width
    property logical_height


    def window; @window.not_nil!; end
    def loader; @loader ||= Loader.new; end
    def fps_counter; @fps_counter; end
    def exit?; @exit; end
    def exit=(@exit : Bool); end
    def title; @title.not_nil!; end

    def width : Int32
      if @logical_width > 0
        @logical_width
      elsif wnd = @window
        wnd.size[0]
      else
        @width || 0
      end
    end

    def height : Int32
      if @logical_height > 0
        @logical_height
      elsif wnd = @window
        wnd.size[1]
      else
        @height || 0
      end
    end

    def center_x; width / 2; end
    def center_y; height / 2; end

    def paused?; @paused; end
    def paused=(@paused : Bool); end

    def toggle_pause
      @paused = !@paused
    end

    def quit!
      @exit = true
    end

    def scene : Scene
      @scenes.last
    end

    protected def current_context : Scene?
      Internal.execution_stack.last?
    end

    private def with_scene_context(scene : Scene, &block)
      Internal.execution_stack << scene
      begin
        yield
      ensure
        Internal.execution_stack.pop
      end
    end

    def push(scene : Scene, data : SwitchData? = nil)
      scene.switch_data = data if data

      with_scene_context(scene) do
        # Per-scene asset loading
        scene.load_assets
        scene.init
      end

      @scenes << scene
    end

    def pop
      @scenes.pop?
    end

    def replace(scene : Scene, data : SwitchData? = nil)
      pop
      push(scene, data)
    end

    def switch(scene : Scene, data : SwitchData? = nil)
      replace(scene, data)
    end

    def switch_async(scene_class : T.class, data : SwitchData? = nil) forall T
      # We instantiate the scene to get its manifest from Loadable
      target_scene = T.new
      tasks = target_scene.manifest

      if tasks.empty?
        switch(target_scene, data)
      else
        loader.add_tasks(tasks)
        loader.start_async
        switch(T.loading_scene_class(scene_class, data))
      end
    end

    protected def check_scenes
    end

    private def update_transitions(dt : Float32)
      if scene.transition_in.running?
        scene.transition_in.update(dt)

        scene.transition_in.clear if scene.transition_in.done?

        return
      end

      if scene.transition_out.running?
        scene.transition_out.update(dt)

        if scene.transition_out.done?
          scene.transition_out.clear
          scene.exit
        end
      end
    end

    def initialize(
      title = "",
      width = 800,
      height = 600,
      logical_width = 0,
      logical_height = 0,
      resizable = false,
      fullscreen = false,
      maximized = false,
      minimized = false,
      borderless = false,
      always_on_top = false,
      high_pixel_density = false,
      renderer_type : Symbol? = nil,
      window_flags : Array(SDL3::Window::Flags)? = nil
    )
      @title = title
      @width = width
      @height = height
      @logical_width = logical_width
      @logical_height = logical_height

      Internal.instance = self

      # Disable macOS Spaces for fullscreen to avoid the "window switching" animation.
      # This MUST be set before SDL3.init to ensure the video driver respects it.
      # This makes 'fullscreen: true' behave like 'Desktop Fullscreen' (on top of everything) on both Win/Mac.
      if fullscreen
        LibSDL3.set_hint(LibSDL3::HINT_VIDEO_MAC_FULLSCREEN_SPACES, "0")
      end

      SDL3.init
      SDL3::TTF.init
      SDL3::Mixer.init

      flags = (window_flags ? window_flags.dup : [SDL3::Window::Flags::None])
      flags << SDL3::Window::Flags::Resizable if resizable || (maximized && !resizable)
      flags << SDL3::Window::Flags::Fullscreen if fullscreen
      flags << SDL3::Window::Flags::Maximized if maximized
      flags << SDL3::Window::Flags::Minimized if minimized
      flags << SDL3::Window::Flags::Borderless if borderless
      flags << SDL3::Window::Flags::AlwaysOnTop if always_on_top
      flags << SDL3::Window::Flags::HighPixelDensity if high_pixel_density

      case renderer_type
      when :open_gl then flags << SDL3::Window::Flags::OpenGL
      when :metal   then flags << SDL3::Window::Flags::Metal
      when :vulkan  then flags << SDL3::Window::Flags::Vulkan
      end

      @window = SDL3::Window.new(
        title,
        width,
        height,
        flags: flags
      )

      if maximized && !resizable
        @window.not_nil!.resizable = false
      end

      SDL3.pump_events

      @window.not_nil!.raise_window

      @draw = Draw.new(@window.not_nil!)
      @draw.not_nil!.vsync = vsync ? 1 : 0
      Internal.draw = @draw.not_nil!
    end

    private def _init
      {% if flag?(:release) %}
        AssetManager.load_pack
      {% end %}

      TextureManager.setup(Game.draw)
      FontManager.setup
      AudioManager.setup
      TileMapManager.setup

      if @logical_width > 0 && @logical_height > 0
        Game.draw.logical_presentation = {@logical_width, @logical_height, SDL3::LogicalPresentation::IntegerScale}
      end

      load_assets

      {% if flag?(:release) %}
        AssetManager.close_pack
      {% end %}
    end

    def vsync
      true
    end

    def joystick_threshold
      1.0
    end

    def mouse_cursor_visible
      true
    end

    def background_color
      DefaultBackgroundColor
    end

    def run
      _init
      init

      # If the user didn't push a scene in `init`, add a default one
      push(Scene.new) if @scenes.empty?

      Events.clear
      @exit = false
      last_frame_time = Time.instant

      while !exit?
        current_time = Time.instant
        delta_time = (current_time - last_frame_time).total_seconds.to_f32
        last_frame_time = current_time

        @fps_counter.update(delta_time)

        InputEvents.update
        loader.update

        Events.handle_events

        break if Events.exit? || exit?

        Performance.instance.measure("update") do
          update(delta_time)
        end

        clear_screen

        Performance.instance.measure("draw") do
          draw
        end

        Performance.instance.end_frame

        if (fps = @target_fps) && fps > 0
          target_duration = 1.0_f32 / fps
          elapsed = (Time.instant - current_time).total_seconds.to_f32

          if elapsed < target_duration
            sleep((target_duration - elapsed).seconds)
          end
        end
      end

      destroy
    end

    def update(dt : Float32)
      return if @scenes.empty?

      to_update = [] of Scene
      @scenes.reverse_each do |s|
        to_update << s
        break unless s.update_underlying?
      end

      to_update.reverse_each do |s|
        with_scene_context(s) do
          if s == scene
            update_transitions(dt)
            if s.transition_in.started? || s.transition_out.started?
              next
            end
          end

          if paused?
            if ps = s.pause_scene
              with_scene_context(ps) do
                ps.update(dt)
              end
            end
          else
            s.update(dt)
          end
        end
      end

      check_scenes

      if !@scenes.empty? && @scenes.last.exit?
        @scenes.pop
        if @scenes.empty?
          self.exit = true
        end
      end
    end

    def clear_screen
      Game.draw.color = background_color
      Game.draw.clear
    end

    def draw
      # Find the index of the first non-transparent scene from the top
      start_index = 0
      (@scenes.size - 1).downto(0) do |i|
        if !@scenes[i].transparent?
          start_index = i
          break
        end
      end

      # Draw from that index upward
      (start_index...@scenes.size).each do |i|
        s = @scenes[i]
        with_scene_context(s) do
          s.draw(Game.draw) unless exit?

          if s == scene
            s.transition_in.draw(Game.draw) if s.transition_in.running?
            s.transition_out.draw(Game.draw) if s.transition_out.started?
          end

          if paused?
            if ps = s.pause_scene
              with_scene_context(ps) do
                ps.draw(Game.draw)
              end
            end
          end
        end
      end

      Game.draw.draw
    end

    def destroy
      Performance.instance.report if performance_monitoring_enabled
      TextureManager.clear_all
      FontManager.clear_all
      AudioManager.clear_all
      TileMapManager.clear_all

      Input.clear
      Keys.clear
      Mouse.clear
      GamePad.clear

      Game.draw.destroy
      window.destroy
      SDL3.quit
    end
  end
end
