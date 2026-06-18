module GSDL
  class AssetManager
    # Private struct to represent an entry in the packfile's manifest
    private struct PackEntry
      property path : String
      property offset : UInt64
      property size : UInt64

      def initialize(@path, @offset, @size)
      end
    end

    # This FormatCode must match the FormatCode in src/packer.cr
    # but we shouldn't include src/packer.cr in GDSL code
    # otherwise it will pack the assets everytime GSDL is required,
    # instead the GSDL consumer should manually pack assets using the
    # provided `gsdl-packer` tool specified in the README, installed via:
    # `crystal lib/game_sdl/install_gsdl_tools.cr`
    FormatCode = "PACK"

    # Holds the parsed manifest: path_key => PackEntry
    @@manifest = Hash(String, PackEntry).new

    # Cache raw data to ensure it stays alive for the lifetime of the application
    # (or until close_pack is called if we decide to clear it there)
    @@data_cache = Hash(String, Bytes).new

    # The File object for the opened assets.pack. Kept open for direct access.
    @@packfile_stream : SDL3::IOStream? = nil
    @@mutex = Mutex.new

    # Base path for loading loose assets in debug mode
    @@asset_path : String = "assets"

    # --- Configuration and State ---

    # Sets the base path for loading loose assets in debug mode.
    def self.asset_path=(path : String)
      @@asset_path = path
    end

    # Returns the base path for loading loose assets.
    def self.asset_path : String
      @@asset_path + "/"
    end

    # Checks if the AssetManager has been initialized (i.e., packfile loaded).
    def self.initialized? : Bool
      @@packfile_stream.is_a?(SDL3::IOStream)
    end

    # --- Packfile Loading ---

    # Loads the assets.pack file and parses its manifest.
    # The packfile is kept open for subsequent asset loading.
    # should only be called in release mode
    def self.load_pack(path : String = "")
      # Determine the actual path to the packfile
      packfile_path = if path.empty?
        {% if flag?(:android) %}
          # On Android, files in the assets folder are relative to the root
          "assets.pack"
        {% else %}
          # If no path is provided, assume it's next to the executable
          exec_dir = if exec_path = Process.executable_path
            File.dirname(exec_path)
          else
            # NOTE: this won't work, unless
            # executed from the same directory
            # like `./executable` instead of `./bin/executable`
            Dir.current
          end

          path = File.join(exec_dir, "assets.pack")

          # On macOS, check if we are in an .app bundle and look in Resources
          {% if flag?(:darwin) %}
            if !File.exists?(path) && exec_dir.ends_with?("/Contents/MacOS")
              resources_path = File.join(File.dirname(exec_dir), "Resources", "assets.pack")
              path = resources_path if File.exists?(resources_path)
            end
          {% end %}

          path
        {% end %}
      else
        # Use the provided path
        GSDL::FS.normalize_path(path)
      end

      if initialized?
        {% if !flag?(:release) %}
          puts "GSDL::AssetManager: Packfile already loaded. Closing existing and reloading."
        {% end %}

        @@packfile_stream.try &.close
      end

      safe_path = GSDL::FS.normalize_path(packfile_path)

      @@packfile_stream = SDL3::IOStream.from_file(safe_path, "rb")
      stream = @@packfile_stream.not_nil!

      # Read magic number
      magic = String.new(stream.read_bytes(4))
      if magic != FormatCode
        raise "GSDL::AssetManager: Invalid packfile magic number. Expected '#{FormatCode}', got '#{magic}'."
      end

      total_entries = stream.read_u32

      # Read manifest entries
      total_entries.times do
        path_len = stream.read_u32
        asset_path = String.new(stream.read_bytes(path_len))
        offset = stream.read_u64
        size = stream.read_u64
        @@manifest[asset_path] = PackEntry.new(path: asset_path, offset: offset, size: size)
      end

      {% if !flag?(:release) %}
        puts "GSDL::AssetManager: Loaded #{@@manifest.size} assets from packfile '#{packfile_path}'."
      {% end %}
    rescue ex
      @@packfile_stream.try &.close
      @@packfile_stream = nil
      raise "GSDL::AssetManager: Failed to load packfile: #{ex.message}"
    end

    # Closes the opened packfile. Should be called when all assets are loaded
    # in release mode, or on application exit
    def self.close_pack
      @@packfile_stream.try &.close
      @@packfile_stream = nil
      # @@manifest.clear # Keep manifest for cache lookup if we decide to clear later

      {% if !flag?(:release) %}
        puts "GSDL::AssetManager: Packfile closed."
      {% end %}
    end

    # --- Raw Data Loading from Packfile ---

    # Reads raw byte data for a given path_key from the loaded packfile.
    # Returns a Bytes object.
    def self.load_raw_data(path_key : String) : Bytes
      # Normalize path key to use forward slashes (POSIX format)
      path_key = path_key.gsub('\\', '/')

      @@mutex.synchronize do
        # Return cached data if available
        if data = @@data_cache[path_key]?
          return data
        end

        unless initialized?
          raise "GSDL::AssetManager: Packfile not loaded. Call AssetManager.load_pack first."
        end

        entry = @@manifest[path_key]?
        unless entry
          raise "GSDL::AssetManager: Asset '#{path_key}' not found in packfile manifest."
        end

        if stream = @@packfile_stream
          stream.seek(entry.offset)
          data = stream.read_bytes(entry.size)

          # Cache it to ensure lifetime
          @@data_cache[path_key] = data

          data
        else
          raise "GSDL::AssetManager: Packfile stream is not initialized."
        end
      end
    end

    # --- SDL3::IOStream Creation from Raw Data ---

    # Creates an SDL3::IOStream from raw byte data.
    # This loads the entire asset into memory before passing it to SDL3.
    # Suitable for smaller to medium-sized assets.
    private def self.io_stream_from_data(data : Bytes) : SDL3::IOStream
      # SDL3::IOStream requires a pointer to constant memory.
      # Crystal's Bytes provides a Pointer.
      SDL3::IOStream.from_memory(data, data.size)
    end

    # Loads raw data from the asset pack
    # and then creates an SDL3::IOStream from raw byte data.
    # This loads the entire asset into memory before passing it to SDL3.
    # Suitable for smaller to medium-sized assets.
    def self.open_io_stream(path_key : String) : SDL3::IOStream
      data = load_raw_data(path_key)
      io_stream_from_data(data)
    end

    def self.with_io_stream(path_key : String, close_io = false)
      data = load_raw_data(path_key)
      io_stream = io_stream_from_data(data)
      begin
        yield io_stream
      ensure
        io_stream.try(&.close) if close_io
      end
    end
  end
end
