require "json"

module GSDL
  module TileMapManager
    @@tile_maps = Hash(String, TileMap).new
    @@registry = Hash(Symbol, String).new
    @@cache = Hash(Symbol, WeakRef(TileMap)).new
    @@mutex = Mutex.new


    def self.get(id : Symbol) : TileMap
      @@mutex.synchronize do
        if weak_ref = @@cache[id]?
          if tile_map = weak_ref.value
            return tile_map
          end
        end

        # Check legacy loaded maps
        if tile_map = @@tile_maps[id.to_s]?
          return tile_map
        end

        path = @@registry[id]? || raise "Asset Registry Error: Symbol :#{id} was never registered!"
        tile_map = load_raw_tile_map(path)
        @@cache[id] = WeakRef.new(tile_map)
        tile_map
      end
    end

    # Housekeeping Maintenance Pass (Call during scene transitions)
    def self.prune_dead_references : Nil
      @@mutex.synchronize do
        @@cache.select! do |key, weak_ref|
          !weak_ref.value.nil?
        end
      end
    end

    # Loads a tile map based on the mode (release/debug).
    def self.load(key : String, path_key : String) : TileMap
      @@mutex.synchronize do
        if @@tile_maps.has_key?(key)
          return @@tile_maps[key]
        end

        tile_map = load_raw_tile_map(path_key)
        @@tile_maps[key] = tile_map
        tile_map
      end
    end

    private def self.load_raw_tile_map(path_key : String) : TileMap
      data = {% if flag?(:release) %}
        # In release mode, defer to AssetManager which handles packfile loading
        manifest_key = path_key.starts_with?("assets/") ? path_key.sub("assets/", "") : path_key
        AssetManager.load_raw_data(manifest_key)
      {% else %}
        # In debug mode, load from loose files
        full_path = if path_key.starts_with?("assets/") || path_key.starts_with?(GSDL::AssetManager.asset_path)
          path_key
        else
          GSDL::AssetManager.asset_path + path_key
        end
        File.open(full_path) do |file|
          slice = Bytes.new(file.size.to_i)
          file.read_fully(slice)
          slice
        end
      {% end %}

      TileMap.from_tiled_data(data)
    end

    def self.register_pair(key : Symbol, val : String)
      @@mutex.synchronize do
        path = val.starts_with?("assets/data/maps/") ? val : "assets/data/maps/#{val}"
        @@registry[key] = path
      end
    end

    def self.register_runtime(mappings : Hash(Symbol, String))
      mappings.each do |key, val|
        register_pair(key, val)
      end
    end

    def self.register_runtime(mappings : NamedTuple)
      mappings.each do |key, val|
        register_pair(key, val.to_s)
      end
    end

    macro register(mappings)
      {% if mappings.is_a?(HashLiteral) || mappings.is_a?(NamedTupleLiteral) %}
        {% for key, val in mappings %}
          ::GSDL::TileMapManager.register_pair(:{{key.id}}, {{val}})
        {% end %}
      {% else %}
        ::GSDL::TileMapManager.register_runtime({{mappings}})
      {% end %}
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
        if @@tile_maps.has_key?(key)
          return @@tile_maps[key]
        end
      end

      raise "TileMap with key '#{key}' not found in TileMapManager. Was it loaded?"
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

        @@cache.clear
        @@registry.clear
      end
    end
  end
end
