module GameSDL
  abstract class Game
    # TODO: might not need window
    # getter window : SDL::Window
    getter renderer : SDL::Renderer
    getter? running
    getter scene_manager : SceneManager
    getter? exit

    # TODO: check / use
    DefaultBackgroundColor = SF::Color.new(0, 0, 0)

    def initialize(title = "")
      SDL.init(SDL::Init::VIDEO)

      window = SDL::Window.new(
        title: title,
        width: 1920,
        height: 1080,
        flags: SDL::Window::Flags::SHOWN | SDL::Window::Flags::RESIZABLE
      )

      @renderer = SDL::Renderer.new(window)

      window.raise
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

    # TODO: check / use
    def background_color
      DefaultBackgroundColor
    end

    def run
      @running = true
      while running?
        while event = SDL::Event.poll
          event(event)
        end

        # TODO:
        update

        renderer.draw_color = SDL::Color.new(30, 30, 30, 255) # Dark Gray
        renderer.clear

        # TODO:
        draw

        renderer.present
      end

      SDL.quit
    end

    def event(event)
      case event
      when SDL::Event::Quit
        @running = false
      when SDL::Event::Keyboard
        @running = false if event.sym.escape?
      end

      # TODO:
      # stage.event(event)
    end

    def update # (frame_time : Float32)
      # TODO:
      # stage.update(frame_time)

      # @exit = true if stage.exit?
    end

    # TODO: switch to renderer class
    def draw
      # TODO: impl

    end
  end
end
