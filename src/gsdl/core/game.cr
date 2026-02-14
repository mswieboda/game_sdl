module GSDL
  abstract class Game
    getter window : SDL3::Window
    getter renderer : Renderer
    getter scene_manager : SceneManager
    getter? exit
    @last_tick : UInt64 = 0_i64

    @@renderer : Renderer?

    def self.renderer : Renderer
      if renderer = @@renderer
        renderer
      else
        raise "Failed to get global renderer"
      end
    end

    DefaultBackgroundColor = Color.new(r: 0, g: 0, b: 0, a: 255)

    def initialize(title = "", width = 1920, height = 1080)
      SDL3.init
      SDL3::TTF.init
      SDL3::Mixer.init

      @window = SDL3::Window.new(
        title,
        width,
        height,
        flags: 32_u64 # This was changed from SDL::WindowFlags::SHOWN | SDL::WindowFlags::RESIZABLE
      )

      @renderer = Renderer.new(window)
      @@renderer = @renderer
      @scene_manager = SceneManager.new
    end

    def init
      {% if flag?(:release) %}
        AssetManager.load_pack
      {% end %}

      TextureManager.setup(renderer)
      FontManager.setup
      AudioManager.setup
      TileMapManager.setup

      load_textures
      load_fonts
      load_audio
      load_tile_maps

      {% if flag?(:release) %}
        AssetManager.close_pack
      {% end %}
    end

    # NOTE: to be overridden by inheritted classes
    def load_textures
    end

    def load_fonts
    end

    def load_audio
    end

    def load_tile_maps
    end

    # TODO: check / use
    def vsync
      true
    end

    # TODO: check / use
    def joystick_threshold
      1.0
    end

    # TODO: check / use
    def mouse_cursor_visible
      true
    end

    def background_color
      DefaultBackgroundColor
    end

    def run
      init

      @exit = false
      @last_tick = SDL3.get_ticks

      while !exit?
        Inputs.update

        current_tick = SDL3.get_ticks
        delta_time_ms = current_tick - @last_tick
        @last_tick = current_tick
        delta_time = delta_time_ms / 1000.0f32

        Events.handle_events

        break if Events.exit? || exit?

        update(delta_time)
        clear_screen
        draw
      end

      destroy
    end

    def update(dt : Float32)
      scene_manager.update(dt)

      @exit = true if scene_manager.exit?
    end

    def clear_screen
      renderer.draw_color = {background_color.r, background_color.g, background_color.b, background_color.a}
      renderer.clear
    end

    def draw
      scene_manager.draw(renderer)

      renderer.present
    end

    def destroy
      TextureManager.clear_all # Unload all textures managed by the singleton
      FontManager.clear_all
      AudioManager.clear_all
      renderer.destroy
      window.destroy
      SDL3.quit
    end
  end
end
