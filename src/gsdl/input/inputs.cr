module GSDL
  module Inputs
    def self.handle_event(event : LibSDL3::Event)
      case event.type
      when GSDL::Keys::KeyDownEvent
        GSDL::Keys.handle_key_down(event)
      when GSDL::Keys::KeyUpEvent
        GSDL::Keys.handle_key_up(event)
      end
    end
  end
end
