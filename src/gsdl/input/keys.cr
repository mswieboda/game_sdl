module GSDL
  module Keys
    enum State
      JustPressed
      Pressed
      JustReleased
    end

    @@states = {} of LibSDL3::Keycode => State

    def self.update
      @@states.each do |key, state|
        case state
        when State::JustPressed
          @@states[key] = State::Pressed
        when State::JustReleased
          @@states.delete(key)
        else
          # No change for Pressed
        end
      end
    end

    def self.handle_key_down(event : LibSDL3::Event)
      key = event.key.key

      # only set to JustPressed if it's not already down
      unless pressed?(key)
        @@states[key] = State::JustPressed
      end
    end

    def self.handle_key_up(event : LibSDL3::Event)
      @@states[event.key.key] = State::JustReleased
    end

    def self.pressed?(key : LibSDL3::Keycode)
      @@states.has_key?(key) && (@@states[key] == State::Pressed || @@states[key] == State::JustPressed)
    end

    def self.pressed?(keys : Array(LibSDL3::Keycode))
      keys.any? { |key| pressed?(key) }
    end

    def self.just_pressed?(key : LibSDL3::Keycode)
      @@states.has_key?(key) && @@states[key] == State::JustPressed
    end

    def self.just_pressed?(keys : Array(LibSDL3::Keycode))
      keys.any? { |key| just_pressed?(key) }
    end

    def self.just_released?(key : LibSDL3::Keycode)
      @@states.has_key?(key) && @@states[key] == State::JustReleased
    end

    def self.just_released?(keys : Array(LibSDL3::Keycode))
      keys.any? { |key| just_released?(key) }
    end
  end
end
