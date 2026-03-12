module GSDL
  alias Event = LibSDL3::Event

  # TODO: alias these events so we
  # don't need to use LibSDL3 internally or for consumers
  module Events
    Quit = LibSDL3::SDL_EVENT_QUIT
    WindowClose = LibSDL3::SDL_EVENT_WINDOW_CLOSE_REQUESTED
    KeyDown = LibSDL3::SDL_EVENT_KEY_DOWN
    KeyUp = LibSDL3::SDL_EVENT_KEY_UP
    MouseMotion = LibSDL3::SDL_EVENT_MOUSE_MOTION
    MouseDown = LibSDL3::SDL_EVENT_MOUSE_BUTTON_DOWN
    MouseUp = LibSDL3::SDL_EVENT_MOUSE_BUTTON_UP
    MouseWheel = LibSDL3::SDL_EVENT_MOUSE_WHEEL
    GamepadButtonDown = LibSDL3::SDL_EVENT_GAMEPAD_BUTTON_DOWN
    GamepadButtonUp = LibSDL3::SDL_EVENT_GAMEPAD_BUTTON_UP
    GamepadAdded = LibSDL3::SDL_EVENT_GAMEPAD_ADDED
    GamepadRemoved = LibSDL3::SDL_EVENT_GAMEPAD_REMOVED
    TextInput = LibSDL3::SDL_EVENT_TEXT_INPUT

    @@esc_exits = false
    @@exit = false

    def self.esc_exits=(esc_exits : Bool)
      @@esc_exits = esc_exits
    end

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
          if @@esc_exits && event.key.key == Keys::Escape
            @@exit = true
          end
        end
        break if @@exit # Break from event polling if quit is signaled

        InputEvents.handle_event(event)
      end
    end
  end
end
