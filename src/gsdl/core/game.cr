module GSDL
  abstract class Game
    getter window : SDL3::Window
    getter renderer : SDL3::Renderer
    getter scene_manager : SceneManager
    getter? exit

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

      while !exit?
        event_processed = false
        event = uninitialized LibSDL3::Event
        while SDL3.poll_event(pointerof(event))
          event_processed = true
          case event.type
          when LibSDL3::SDL_EVENT_QUIT, LibSDL3::SDL_EVENT_WINDOW_CLOSE_REQUESTED
            @exit = true
          when LibSDL3::SDL_EVENT_KEY_DOWN
            if event.key.key == LibSDL3::ESCAPE
              @exit = true
            end
          end
          break if @exit # Break from event polling if quit is signaled
        end

        break if @exit # Break from main loop if quit is signaled

        # TODO: figure out how to do frame_time with SDL2
        update(0.123)
        clear_screen
        draw
        # Consider getting these from a window getter if added later.
        renderer.present
      end

      destroy
    end

    def update(frame_time : Float32)
      scene_manager.update(frame_time)

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
