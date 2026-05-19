require "json"

module GSDL
  module TileMapManager
    @@tile_maps = Hash(String, TileMap).new
    @@mutex = Mutex.new

    # Sets up the TileMapManager.
    # Note: TileMapManager is now initialized automatically, but this method
    # is kept for consistency with other managers.
    def self.setup
    end

    # Loads a tile map based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending GSDL::AssetManager.asset_path.
    def self.load(key : String, path_key : String) : TileMap
      @@mutex.synchronize do
        if @@tile_maps.has_key?(key)
          return @@tile_maps[key]
        end

        data = {% if flag?(:release) %}
          # In release mode, defer to AssetManager which handles packfile loading
          AssetManager.load_raw_data(path_key)
        {% else %}
          # In debug mode, load from loose files
          full_path = GSDL::AssetManager.asset_path + path_key
          File.open(full_path) do |file|
            slice = Bytes.new(file.size.to_i)
            file.read_fully(slice)
            slice
          end
        {% end %}

        tile_map = TileMap.from_tiled_data(data)
        @@tile_maps[key] = tile_map
        tile_map
      end
    end

    # Loads tile map from raw byte data and associates it with a key
    def self.load_from_memory(key : String, data : Bytes) : TileMap
      @@mutex.synchronize do
        if @@tile_maps.has_key?(key)
          return @@tile_maps[key]
        end
        tile_map = TileMap.from_tiled_data(data)
        @@tile_maps[key] = tile_map
        tile_map
      end
    end

    # Retrieves a loaded tile map by its key.
    def self.get(key : String) : TileMap
      @@mutex.synchronize do
        @@tile_maps[key]? || raise "TileMap with key '#{key}' not found in TileMapManager. Was it loaded?"
      end
    end

    # Unloads a specific tile map from memory.
    def self.unload(key : String) : Nil
      @@mutex.synchronize do
        @@tile_maps.delete(key)
      end
    end

    # Unloads all managed tile map assets from memory.
    def self.clear_all : Nil
      @@mutex.synchronize do
        @@tile_maps.clear
      end
    end
  end
end
