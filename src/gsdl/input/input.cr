module GSDL
  module Input
    @@actions = {} of Symbol => -> Bool

    # Define an action with a block that returns a Bool
    # Example: GSDL::Input.set(:jump) { GSDL::Keys.just_pressed?(GSDL::Keys::Space) }
    def self.set(name : Symbol, &block : -> Bool)
      @@actions[name] = block
    end

    # Check if an action is currently active
    # Example: if GSDL::Input.action?(:jump)
    def self.action?(name : Symbol) : Bool
      if action = @@actions[name]?
        action.call
      else
        false
      end
    end

    # Shorthand for action?
    def self.[](name : Symbol) : Bool
      action?(name)
    end

    # Clear all actions
    def self.clear
      @@actions.clear
    end

    # Remove a specific action
    def self.delete(name : Symbol)
      @@actions.delete(name)
    end

    @@multi_tap_time_window : UInt64 = 250_u64

    def self.multi_tap_time_window=(val : UInt64)
      @@multi_tap_time_window = val
      Keys.multi_tap_tracker.time_window = val
      Mouse.multi_tap_tracker.time_window = val
      GamePad.multi_tap_tracker.time_window = val
    end

    def self.multi_tap_time_window
      @@multi_tap_time_window
    end

    @@text_input_this_frame : String = ""

    def self.text_input_this_frame : String
      @@text_input_this_frame
    end

    def self.append_text_input(text : String)
      @@text_input_this_frame += text
    end

    def self.clear_text_input
      @@text_input_this_frame = ""
    end

    def self.start_text_input
      LibSDL3.start_text_input(Game.instance.window.to_unsafe)
    end

    def self.stop_text_input
      LibSDL3.stop_text_input(Game.instance.window.to_unsafe)
    end

    def self.text_input_active? : Bool
      LibSDL3.text_input_active(Game.instance.window.to_unsafe)
    end
  end
end
