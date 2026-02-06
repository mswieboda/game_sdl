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
      GSDL::TextureManager.setup(renderer)

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
        GSDL::Keys.update

        current_tick = SDL3.get_ticks
        delta_time_ms = current_tick - @last_tick
        @last_tick = current_tick
        delta_time = delta_time_ms / 1000.0f32

        event = uninitialized LibSDL3::Event
        while SDL3.poll_event(pointerof(event))
          case event.type
          when LibSDL3::SDL_EVENT_QUIT, LibSDL3::SDL_EVENT_WINDOW_CLOSE_REQUESTED
            @exit = true
          when LibSDL3::SDL_EVENT_KEY_DOWN
            if event.key.key == LibSDL3::ESCAPE
              @exit = true
            end
          end
          break if @exit # Break from event polling if quit is signaled

          GSDL::Inputs.handle_event(event)
        end

        break if @exit # Break from main loop if quit is signaled

        GSDL::Inputs.handle_event(event)

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
      GSDL::TextureManager.clear_all # Unload all textures managed by the singleton
      renderer.destroy
      window.destroy
      SDL3::TTF.quit
      SDL3.quit
    end
  end
end
