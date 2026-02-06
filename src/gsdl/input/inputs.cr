module GSDL
  module Inputs
    def self.handle_event(event : Event)
      case event.type
      when Events::KeyDown
        Keys.handle_key_down(event)
      when Events::KeyUp
        Keys.handle_key_up(event)
      end
    end
  end
end
