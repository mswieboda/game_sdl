require "json"

module GSDL
  class TileMapManager
    @@instance : TileMapManager? = nil

    @tile_maps : Hash(String, TileMap)

    private def initialize
      @tile_maps = Hash(String, TileMap).new
    end

    # Sets up the singleton instance of TileMapManager.
    # This should be called once at the start of the application,
    def self.setup
      raise "TileMapManager already set up!" if @@instance
      @@instance = new
    end

    # Retrieves the singleton instance of TileMapManager.
    # Raises an error if setup has not been called.
    def self.instance : TileMapManager
      @@instance || raise("TileMapManager has not been set up. Call GSDL::TileMapManager.setup first.")
    end

    # Loads a tile map based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending GSDL::AssetManager.asset_path.
    def self.load(key : String, path_key : String) : TileMap
      # see TextureManager.load comments for more details on path_key
      # which is a key based on the path like 'gfx/map.json'
      # and will either load from the asset.pack file in release mode
      # or from the 'assets/gfx/map.json' file directly in debug mode

      # Using flag?(:release) for compile-time conditional compilation.
      # When compiling with `crystal build --release`, the :release flag is set.
      {% if flag?(:release) %}
        # In release mode, defer to AssetManager which handles packfile loading
        data = AssetManager.load_raw_data(path_key)
        load_from_memory(key, data)
      {% else %}
        # In debug mode, load from loose files
        full_path = GSDL::AssetManager.asset_path + path_key
        instance.load(key, full_path)
      {% end %}
    end

    # Loads tile map from raw byte data and associates it with a key
    # This method is primarily intended to be called by load if in release mode
    def self.load_from_memory(key : String, data : Bytes) : TileMap
      instance.load_from_memory(key, data)
    end

    # Retrieves a loaded tile map by its key.
    def self.get(key : String) : TileMap
      instance.get(key) # Delegate to the internal instance method
    end

    # Unloads a specific tile map from memory.
    def self.unload(key : String) : Nil
      instance.unload(key) # Delegate to the internal instance method
    end

    # Unloads all managed tile map assets from memory.
    def self.clear_all : Nil
      instance.clear_all # Delegate to the internal instance method
    end

    # --- Instance methods (called by class methods via the singleton instance) ---

    def load(key : String, path : String) : TileMap
      if @tile_maps.has_key?(key)
        return @tile_maps[key]
      end
      tile_map = TileMap.from_tiled_file(path)
      @tile_maps[key] = tile_map
      tile_map
    end

    def load_from_memory(key : String, data : Bytes) : TileMap
      if @tile_maps.has_key?(key)
        return @tile_maps[key]
      end
      tile_map = TileMap.from_tiled_data(data)
      @tile_maps[key] = tile_map
      tile_map
    end

    def get(key : String) : TileMap
      @tile_maps.fetch(key) do
        raise "TileMap with key '#{key}' not found in TileMapManager. Was it loaded?"
      end
    end

    def unload(key : String) : Nil
      @tile_maps.delete(key)
    end

    def clear_all : Nil
      @tile_maps.clear
    end
  end
end
