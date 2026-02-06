module GSDL
  abstract class Game
    getter window : SDL3::Window
    getter renderer : SDL3::Renderer
    getter scene_manager : SceneManager
    getter? exit
    @last_tick : UInt64 = 0_i64

    DefaultBackgroundColor = LibSDL3::Color.new(r: 0, g: 0, b: 0, a: 255)

    def initialize(title = "", width = 1920, height = 1080)
      SDL3.init(LibSDL3::SDL_INIT_VIDEO)
      SDL3::TTF.init

      @window = SDL3::Window.new(
        title,
        width,
        height,
        flags: 32_u64 # This was changed from SDL::WindowFlags::SHOWN | SDL::WindowFlags::RESIZABLE
      )

      @renderer = SDL3::Renderer.new(window)
      @scene_manager = SceneManager.new
    end

    def init
      TextureManager.setup(renderer)

      load_textures
    end

    # NOTE: to be overridden by inheritted classes
    def load_textures
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
        Keys.update

        current_tick = SDL3.get_ticks
        delta_time_ms = current_tick - @last_tick
        @last_tick = current_tick
        delta_time = delta_time_ms / 1000.0f32

        Events.handle_events

        break if Events.exit? || exit?

        update(delta_time)
        clear_screen
        draw

        # Consider getting these from a window getter if added later.
        renderer.present
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
    end

    def destroy
      TextureManager.clear_all # Unload all textures managed by the singleton
      renderer.destroy
      window.destroy
      SDL3::TTF.quit
      SDL3.quit
    end
  end
end
