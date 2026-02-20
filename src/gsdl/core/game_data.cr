require "json"

module GSDL
  class GameData
    @data : Hash(String, JSON::Any)

    def initialize
      @data = {} of String => JSON::Any
    end

    # Access the raw data hash
    def data
      @data
    end

    # Set a value at a specific key path
    # Example: Data.set("player", "score", 100)
    def set(key : String, value)
      @data[key] = JSON.parse(value.to_json)
    end

    # Set nested values using multiple keys
    # Example: Data.set(["quests", "apples", "collected"], 5)
    def set(keys : Array(String), value)
      return if keys.empty?
      
      if keys.size == 1
        set(keys[0], value)
        return
      end

      # Navigate or create the tree
      current = @data
      keys[0...-1].each do |key|
        unless current.has_key?(key) && current[key].as_h?
          current[key] = JSON.parse("{}")
        end
        current = current[key].as_h
      end
      
      current[keys.last] = JSON.parse(value.to_json)
    end

    # Get a value, returns JSON::Any
    def get(key : String) : JSON::Any
      @data[key]? || JSON::Any.new(nil)
    end

    # Deep get using multiple keys
    # Example: Data.dig("quests", "apples", "collected")
    def dig(*keys : String) : JSON::Any
      current = JSON::Any.new(@data)
      keys.each do |key|
        if next_val = current[key]?
          current = next_val
        else
          return JSON::Any.new(nil)
        end
      end
      current
    end

    # Shorthand for dig
    def [](*keys : String)
      dig(*keys)
    end

    # Convenience for boolean checks
    # Example: if Data.true?("level1", "solved")
    def true?(*keys : String) : Bool
      dig(*keys).as_bool? == true
    end

    # Shorthand for incrementing a number
    def increment(key : String, amount = 1)
      val = get(key).as_i? || 0
      set(key, val + amount)
    end

    # Save the entire state to a JSON file
    def save(path : String)
      File.write(path, @data.to_json)
    end

    # Load state from a JSON file
    def load(path : String)
      if File.exists?(path)
        @data = Hash(String, JSON::Any).from_json(File.read(path))
      end
    end

    # Clear all data
    def clear
      @data.clear
    end
  end

  # Global Singleton
  Data = GameData.new
end
