module GameSDL
  abstract class Game
    getter window : SDL3::Window
    getter renderer : SDL3::Renderer
    getter scene_manager : SceneManager
    getter? exit

    DefaultBackgroundColor = LibSDL3::Color.new(r: 0, g: 0, b: 0, a: 255)

    def initialize(title = "")
      SDL3.init(LibSDL3::SDL_INIT_VIDEO); at_exit { SDL3.quit }

      SDL3::TTF.init; at_exit { SDL3::TTF.quit }

      @window = SDL3::Window.new(
        title,
        1920,
        1080,
        flags: 32_u64 # This was changed from SDL::WindowFlags::SHOWN | SDL::WindowFlags::RESIZABLE
      )

      @renderer = SDL3::Renderer.new(window)
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
      puts "Game loop started."

      while !exit?
        puts "Loop iteration. exit? = #{exit?}"
        event_processed = false
        event = uninitialized LibSDL3::Event
        while SDL3.poll_event(pointerof(event))
          event_processed = true
          puts "  Event received: type #{event.type}"
          case event.type
          when LibSDL3::SDL_EVENT_QUIT, LibSDL3::SDL_EVENT_WINDOW_CLOSE_REQUESTED
            puts "    Quit event received. Setting @exit = true."
            @exit = true
          when LibSDL3::SDL_EVENT_KEY_DOWN
            puts "    Keydown event. Keycode: #{event.key.key}"
            if event.key.key == LibSDL3::ESCAPE
              puts "    ESC key pressed. Setting @exit = true."
              @exit = true
            end
          end
          break if @exit # Break from event polling if quit is signaled
        end
        puts "Events processed in this iteration: #{event_processed}. After event processing, exit? = #{exit?}"

        break if @exit # Break from main loop if quit is signaled

        # TODO: figure out how to do frame_time with SDL2
        update(0.123)
        clear_screen
        draw(1920, 1080) # Using hardcoded dimensions for now, as they are used to create the window
        # Consider getting these from a window getter if added later.
        renderer.present
      end

      puts "Game loop terminated. Calling SDL3.quit."
      SDL3.quit
    end



    def update(frame_time : Float32)
      scene_manager.update(frame_time)

      @exit = true if scene_manager.exit?
    end

    def clear_screen
      renderer.draw_color = {background_color.r, background_color.g, background_color.b, background_color.a}
      renderer.clear
    end

    # TODO: switch to renderer class architecture
    def draw(window_width : Int32, window_height : Int32)
      # TODO: impl
      scene_manager.draw(renderer)
    end
  end
end
