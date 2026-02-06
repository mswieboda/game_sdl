module GSDL
  alias Event = LibSDL3::Event

  module Events
    Quit = LibSDL3::SDL_EVENT_QUIT
    WindowClose = LibSDL3::SDL_EVENT_WINDOW_CLOSE_REQUESTED
    KeyDown = LibSDL3::SDL_EVENT_KEY_DOWN
    KeyUp = LibSDL3::SDL_EVENT_KEY_UP
    MouseMotion = LibSDL3::SDL_EVENT_MOUSE_MOTION
    MouseDown = LibSDL3::SDL_EVENT_MOUSE_BUTTON_DOWN
    MouseUp = LibSDL3::SDL_EVENT_MOUSE_BUTTON_UP

    @@exit = false

    def self.exit?
      @@exit
    end

    def self.handle_events
      event = uninitialized Event
      while SDL3.poll_event(pointerof(event))
        case event.type
        when Quit, WindowClose
          @@exit = true
        when KeyDown
          if event.key.key == Keys::Escape
            @@exit = true
          end
        end
        break if @@exit # Break from event polling if quit is signaled

        Inputs.handle_event(event)
      end
    end
  end
end
