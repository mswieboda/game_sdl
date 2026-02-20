require "./keys"
require "./mouse"
require "./game_pad"

module GSDL
  module InputEvents
    def self.update
      Keys.update
      Mouse.update
      GamePad.update
    end

    def self.handle_event(event : Event)
      case event.type
      when Events::KeyDown
        Keys.handle_key_down(event)
      when Events::KeyUp
        Keys.handle_key_up(event)
      when Events::MouseMotion
        Mouse.handle_mouse_motion(event)
      when Events::MouseDown
        Mouse.handle_mouse_button_down(event)
      when Events::MouseUp
        Mouse.handle_mouse_button_up(event)
      when Events::GamepadButtonDown
        GamePad.handle_gamepad_button_down(event)
      when Events::GamepadButtonUp
        GamePad.handle_gamepad_button_up(event)
      when Events::GamepadAdded
        GamePad.handle_gamepad_added(event)
      when Events::GamepadRemoved
        GamePad.handle_gamepad_removed(event)
      end
    end
  end
end