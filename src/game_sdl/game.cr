module GameSDL
  abstract class Game
    getter renderer : SDL::Renderer
    getter scene_manager : SceneManager
    getter? exit

    DefaultBackgroundColor = SDL::Color.new(0, 0, 0, 255)

    def initialize(title = "")
      SDL.init(SDL::Init::VIDEO)

      window = SDL::Window.new(
        title: title,
        width: 1920,
        height: 1080,
        flags: SDL::Window::Flags::SHOWN | SDL::Window::Flags::RESIZABLE
      )

      @renderer = SDL::Renderer.new(window)
      @scene_manager = SceneManager.new
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
      @exit = false

      window.raise

      while !exit?
        while event = SDL::Event.poll
          event(event)
        end

        # TODO: figure out how to do frame_time with SDL2
        update(0.123)
        clear_screen
        draw

        renderer.present
      end

      SDL.quit
    end

    def event(event)
      case event
      when SDL::Event::Quit
        @exit = true
      when SDL::Event::Keyboard
        @exit = true if event.sym.escape?
      end

      scene_manager.event(event)
    end

    def update(frame_time : Float32)
      scene_manager.update(frame_time)

      @exit = true if scene_manager.exit?
    end

    def clear_screen
      renderer.draw_color = background_color
      renderer.clear
    end

    # TODO: switch to renderer class architecture
    def draw
      # TODO: impl
      scene_manager.draw(renderer)
    end
  end
end
