require "json"
require "compress/zlib"
require "digest/crc32"

module GSDL
  # NOTE: can be accessed from GSDL::Data singleton
  # defined at the bottom of this file
  class GameData
    @data : Hash(String, JSON::Any)
    private XOR_KEY = 0xAAu8

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
    def save_json(path : String)
      File.write(path, @data.to_json)
    end

    # Save the entire state to a binary file
    def save_binary(path : String)
      json_data = @data.to_json
      compressed = IO::Memory.new
      Compress::Zlib::Writer.open(compressed) { |w| w.print json_data }
      payload = compressed.to_slice

      # XOR Obfuscation
      payload.map! { |b| b ^ XOR_KEY }

      checksum = Digest::CRC32.checksum(payload)

      tmp_path = "#{path}.tmp"
      File.open(tmp_path, "wb") do |f|
        f.write "GSDL".to_slice    # Magic Number
        f.write_bytes 1u32         # Version
        f.write_bytes checksum     # Checksum
        f.write payload
      end
      File.rename(tmp_path, path)
    end

    # Default save uses binary format
    def save(path : String)
      save_binary(path)
    end

    # Load state from a file, auto-detecting binary or JSON format
    def load(path : String)
      return unless File.exists?(path)

      File.open(path, "rb") do |f|
        magic = f.read_string(4)
        if magic == "GSDL"
          version = f.read_bytes(UInt32)
          checksum = f.read_bytes(UInt32)
          payload = f.gets_to_end.to_slice

          # Verify Checksum
          if Digest::CRC32.checksum(payload) != checksum
            puts "Error: Binary save file checksum mismatch for #{path}"
            return
          end

          # Undo XOR
          writable_payload = payload.dup
          writable_payload.map! { |b| b ^ XOR_KEY }

          # Decompress
          json_data = IO::Memory.new(writable_payload)
          decompressed = Compress::Zlib::Reader.open(json_data) { |r| r.gets_to_end }
          @data = Hash(String, JSON::Any).from_json(decompressed)
        else
          # Fallback to JSON
          f.rewind
          @data = Hash(String, JSON::Any).from_json(f.gets_to_end)
        end
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
