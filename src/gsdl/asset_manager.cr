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

    # The File object for the opened assets.pack. Kept open for direct access.
    @@packfile_io : File? = nil

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
      @@packfile_io.is_a?(File)
    end

    # --- Packfile Loading ---

    # Loads the assets.pack file and parses its manifest.
    # The packfile is kept open for subsequent asset loading.
    # should only be called in release mode
    def self.load_pack(path : String = "")
      # Determine the actual path to the packfile
      packfile_path = if path.empty?
        # If no path is provided, assume it's next to the executable
        exec_dir = if exec_path = Process.executable_path
          File.dirname(exec_path)
        else
          # NOTE: this won't work, unless
          # executed from the same directory
          # like `./executable` instead of `./bin/executable`
          Dir.current
        end

        File.join(exec_dir, "assets.pack")
      else
        # Use the provided path
        path
      end

      if initialized?
        puts "GSDL::AssetManager: Packfile already loaded. Closing existing and reloading."
        @@packfile_io.try &.close
      end

      unless File.exists?(packfile_path)
        raise "GSDL::AssetManager: Packfile not found at '#{packfile_path}'. Cannot load assets."
      end

      @@packfile_io = File.open(packfile_path, "r")
      file = @@packfile_io.not_nil!

      # Read magic number
      magic = Bytes.new(4)
      file.read_fully(magic)
      magic_str = String.new(magic)
      if magic_str != FormatCode
        file.close
        @@packfile_io = nil
        raise "GSDL::AssetManager: Invalid packfile magic number. Expected '#{FormatCode}', got '#{magic_str}'."
      end

      # Read entry count
      entry_count = file.read_bytes(UInt32, IO::ByteFormat::LittleEndian)

      # Read manifest entries
      entry_count.times do
        path_len = file.read_bytes(UInt32, IO::ByteFormat::LittleEndian)
        path_bytes = Bytes.new(path_len)
        file.read_fully(path_bytes)
        asset_path = String.new(path_bytes)
        offset = file.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
        size = file.read_bytes(UInt64, IO::ByteFormat::LittleEndian)
        @@manifest[asset_path] = PackEntry.new(path: asset_path, offset: offset, size: size)
      end

      puts "GSDL::AssetManager: Loaded #{@@manifest.size} assets from packfile '#{packfile_path}'."
    rescue ex
      @@packfile_io.try &.close
      @@packfile_io = nil
      raise "GSDL::AssetManager: Failed to load packfile: #{ex.message}"
    end

    # Closes the opened packfile. Should be called when all assets are loaded
    # in release mode, or on application exit
    def self.close_pack
      @@packfile_io.try &.close
      @@packfile_io = nil
      @@manifest.clear
      puts "GSDL::AssetManager: Packfile closed."
    end

    # --- Raw Data Loading from Packfile ---

    # Reads raw byte data for a given path_key from the loaded packfile.
    # Returns a Bytes object.
    def self.load_raw_data(path_key : String) : Bytes
      unless initialized?
        raise "GSDL::AssetManager: Packfile not loaded. Call AssetManager.load_pack first."
      end

      entry = @@manifest[path_key]?
      unless entry
        raise "GSDL::AssetManager: Asset '#{path_key}' not found in packfile manifest."
      end

      file = @@packfile_io.not_nil!
      file.seek(entry.offset, IO::Seek::Set)

      data = Bytes.new(entry.size)
      file.read_fully(data)
      data
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
