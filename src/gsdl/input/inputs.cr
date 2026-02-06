module GSDL
  module Inputs
    def self.handle_event(event : LibSDL3::Event)
      case event.type
      when LibSDL3::SDL_EVENT_KEY_DOWN
        GSDL::Keys.handle_key_down(event)
      when LibSDL3::SDL_EVENT_KEY_UP
        GSDL::Keys.handle_key_up(event)
      end
    end
  end
end
