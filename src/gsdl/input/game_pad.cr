module GSDL
  # TODO: wrap our alias LibSDL3 and SDL3 usages
  # so consumers don't need to use LibSDL3
  module GamePad
    enum State
      JustPressed
      Pressed
      JustReleased
    end

    @@states = {} of LibSDL3::GamepadButton => State
    @@gamepads = {} of LibSDL3::JoystickID => SDL3::Gamepad::GamepadWrapper
    @@multi_tap_tracker = GSDL::Input::MultiTapTracker(LibSDL3::GamepadButton).new

    def self.multi_tap_tracker
      @@multi_tap_tracker
    end

    def self.update
      # Update button states
      @@states.each do |button, state|
        case state
        when State::JustPressed
          @@states[button] = State::Pressed
        when State::JustReleased
          @@states.delete(button)
        else
          # No change for Pressed
        end
      end
      @@multi_tap_tracker.update(LibSDL3.get_ticks)

      # Update SDL gamepads
      LibSDL3.update_gamepads

      # Check for newly connected gamepads
      # TODO: Implement connection/disconnection handling via SDL events
      # For now, let's just make sure existing ones are tracked
    end

    def self.handle_gamepad_button_down(event : LibSDL3::Event)
      button = LibSDL3::GamepadButton.new(event.gbutton.button.to_i)
      gamepad_id = event.gbutton.which

      # Ensure the gamepad is tracked
      unless @@gamepads.has_key?(gamepad_id)
        if gamepad_wrapper = SDL3::Gamepad.open_gamepad(gamepad_id)
          @@gamepads[gamepad_id] = gamepad_wrapper
        else
          return # Could not open gamepad
        end
      end

      # Update button state
      unless pressed?(button, gamepad_id)
        @@states[button] = State::JustPressed
        @@multi_tap_tracker.record_tap(button, LibSDL3.get_ticks)
      end
    end

    def self.handle_gamepad_button_up(event : LibSDL3::Event)
      button = LibSDL3::GamepadButton.new(event.gbutton.button.to_i)
      @@states[button] = State::JustReleased
    end

    def self.handle_gamepad_added(event : LibSDL3::Event)
      gamepad_id = event.gdevice.which
      if gamepad_wrapper = SDL3::Gamepad.open_gamepad(gamepad_id)
        @@gamepads[gamepad_id] = gamepad_wrapper
        puts "Gamepad '#{gamepad_wrapper.name}' (ID: #{gamepad_id}) connected."
      end
    end

    def self.handle_gamepad_removed(event : LibSDL3::Event)
      gamepad_id = event.gdevice.which
      if gamepad_wrapper = @@gamepads.delete(gamepad_id)
        gamepad_wrapper.destroy
        puts "Gamepad (ID: #{gamepad_id}) disconnected."
      end
    end

    def self.pressed?(button : LibSDL3::GamepadButton, gamepad_id : LibSDL3::JoystickID? = nil) : Bool
      # If gamepad_id is provided, check the specific gamepad.
      # Otherwise, check if the button is pressed on any connected gamepad.
      if gamepad_id
        gamepad = @@gamepads[gamepad_id.as(LibSDL3::JoystickID)]?
        return gamepad.button(button) if gamepad
        return false
      else
        return @@gamepads.any? { |id, gp| gp.button(button) }
      end
    end

    def self.just_pressed?(button : LibSDL3::GamepadButton, gamepad_id : LibSDL3::JoystickID? = nil) : Bool
      # Similar logic to pressed?, but using @@states
      if gamepad_id
        # For JustPressed/JustReleased, we rely on our internal @@states
        # If the button's state is JustPressed for the given gamepad, return true
        # Need to consider if @@states should be keyed by [gamepad_id, button]
        # For simplicity, let's just check global state for now
        @@states.has_key?(button) && @@states[button] == State::JustPressed
      else
        @@states.has_key?(button) && @@states[button] == State::JustPressed
      end
    end

    def self.just_released?(button : LibSDL3::GamepadButton, gamepad_id : LibSDL3::JoystickID? = nil) : Bool
      if gamepad_id
        @@states.has_key?(button) && @@states[button] == State::JustReleased
      else
        @@states.has_key?(button) && @@states[button] == State::JustReleased
      end
    end

    def self.axis_value(axis : LibSDL3::GamepadAxis, gamepad_id : LibSDL3::JoystickID? = nil) : Int16
      if gamepad_id
        gamepad = @@gamepads[gamepad_id.as(LibSDL3::JoystickID)]?
        return gamepad.axis(axis) if gamepad
        return 0_i16
      else
        # If no specific gamepad_id, return the value from the first connected gamepad
        # Or an average, or highest absolute value. For now, first one.
        if gp = @@gamepads.values.first?
          return gp.axis(axis)
        end
        return 0_i16
      end
    end

    def self.multi_tap?(button : LibSDL3::GamepadButton, count : Int32) : Bool
      @@multi_tap_tracker.multi_tap?(button, count)
    end

    def self.double_tap?(button : LibSDL3::GamepadButton) : Bool
      @@multi_tap_tracker.double_tap?(button)
    end

    def self.tap_count(button : LibSDL3::GamepadButton) : Int32
      @@multi_tap_tracker.tap_count(button)
    end

    # TODO: Add methods for rumble, LED, etc. if needed later
  end
end