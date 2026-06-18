module GSDL
  module FS
    # Cleans asset paths to match platform expectations
    def self.normalize_path(path : String) : String
      {% if flag?(:android) %}
        # Strip leading "./assets/" or "assets/" for the Android asset manager
        cleaned = path.sub(%r{^\./}, "")

        if cleaned.starts_with?("assets/")
          cleaned = cleaned.sub("assets/", "")
        end

        cleaned
      {% else %}
        # Keep path as-is for Desktop builds
        path
      {% end %}
    end

    # Reads a bundled application asset completely into a Bytes slice
    def self.read_asset(path : String) : Bytes
      # Clean the path before opening the stream
      safe_path = normalize_path(path)
      stream = SDL3::IOStream.from_file(safe_path, "rb")

      begin
        stream.read_all
      ensure
        stream.close
      end
    end

    # Reads a bundled application asset directly into a String
    def self.read_asset_string(path : String) : String
      bytes = self.read_asset(path)
      String.new(bytes)
    end

    # Returns a writable directory path specific to your game
    def self.save_directory : String
      # Caches the string path so we aren't constantly querying the native layer
      @@save_dir ||= begin
        SDL3::FileSystem.pref_path(Game.org_name, Game.title_name)
      end
    end
  end
end
