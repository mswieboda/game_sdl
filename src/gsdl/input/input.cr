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
  end
end
