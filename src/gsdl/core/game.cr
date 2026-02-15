module GSDL
  def self.ticks
    SDL3.get_ticks
  end

  abstract class Game
    DefaultBackgroundColor = Colors::Black

    @@draw : Draw?

    getter window : SDL3::Window
    getter scene_manager : SceneManager
    getter? exit

    @draw : Draw
    @last_tick : UInt64 = 0_i64

    def self.draw_instance : Draw
      if draw = @@draw
        draw
      else
        raise "Failed to get global draw"
      end
    end

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

      @draw = Draw.new(window)
      @@draw = @draw
      @scene_manager = SceneManager.new
    end

    def init
      {% if flag?(:release) %}
        AssetManager.load_pack
      {% end %}

      TextureManager.setup(@draw)
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
      @last_tick = GSDL.ticks

      while !exit?
        Inputs.update

        current_tick = GSDL.ticks
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
      @draw.color = background_color
      @draw.clear
    end

    def draw
      scene_manager.draw(@draw)

      @draw.draw
    end

    def destroy
      TextureManager.clear_all # Unload all textures managed by the singleton
      FontManager.clear_all
      AudioManager.clear_all
      TileMapManager.clear_all
      @draw.destroy
      window.destroy
      SDL3.quit
    end
  end
end
