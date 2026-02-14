require "json"

module GSDL
  class TileMap
    alias Num = Int32 | Float32

    # Using a 2D array of Int32 to store global tile IDs.
    property map_data : Array(Array(Int32))
    # Map of tileset key to Tileset object
    property tilesets : Hash(String, Tileset)
    property tile_width : Int32
    property tile_height : Int32
    property map_width_tiles : Int32
    property map_height_tiles : Int32
    property tiled_tilesets : Array(JSON::Any)

    def initialize(@tile_width, @tile_height)
      @map_data = [] of Array(Int32)
      @tilesets = {} of String => Tileset
      @map_width_tiles = 0
      @map_height_tiles = 0
      @tiled_tilesets = [] of JSON::Any
    end

    def self.from_tiled_json(json : JSON::Any) : TileMap
      tile_w = json["tilewidth"].as_i
      tile_h = json["tileheight"].as_i
      map_w = json["width"].as_i
      map_h = json["height"].as_i

      tile_map = TileMap.new(tile_w, tile_h)
      tile_map.map_width_tiles = map_w
      tile_map.map_height_tiles = map_h

      tiled_tilesets = json["tilesets"].as_a

      tiled_tilesets.each do |ts_data|
        name = ts_data["name"].as_s
        image_path = "assets/gfx/" + ts_data["image"].as_s

        texture = GSDL::TextureManager.get(name)

        # Create and configure the tileset
        tileset = GSDL::Tileset.new(
          texture,
          ts_data["tilewidth"].as_i,
          ts_data["tileheight"].as_i,
          ts_data["firstgid"].as_i
        )

        tileset.solid_tiles = ts_data["solid_tiles"].as_a.map(&.as_i)

        tile_map.add_tileset(name, tileset)
      end

      layer_data = json["layers"][0]["data"].as_a.map(&.as_i)
      chunked_data = chunk_data(layer_data, map_w)
      tile_map.map_data = chunked_data
      tile_map
    end

    def self.from_tiled_file(filepath : String) : TileMap
      from_tiled_json(JSON.parse(File.read(filepath)))
    end

    def self.from_tiled_data(data : Bytes)
      from_tiled_json(JSON.parse(String.new(data)))
    end

    # Adds a tileset to the map with a given key
    def add_tileset(key : String, tileset : Tileset)
      @tilesets[key] = tileset
    end

    # Loads map data from a simple 2D array for demonstration
    def load_map_data(data : Array(Array(Int32)))
      @map_data = data
      @map_height_tiles = data.size
      @map_width_tiles = data.empty? ? 0 : data[0].size
    end

    private def self.chunk_data(data : Array(Int32), width : Int32) : Array(Array(Int32))
      result = [] of Array(Int32)
      (data.size / width).to_i.times do |i|
        start_index = i * width
        end_index = start_index + width
        result << data[start_index...end_index]
      end
      result
    end

    # Translates a global_gid into a Tileset and its local_tile_id
    def find_tileset_and_local_id(global_gid : Int32) : TileInfo?
      # A global_gid of 0 typically means an empty tile in Tiled
      return nil if global_gid == 0

      @tilesets.each do |key, tileset|
        if tileset.contains_gid?(global_gid)
          local_tile_id = global_gid - tileset.first_gid
          return TileInfo.new(key, local_tile_id, tileset.solid?(global_gid))
        end
      end
      nil # No tileset found for this global_gid
    end

    def solid_at?(x : Int32, y : Int32) : Bool
      tile_x = x // @tile_width
      tile_y = y // @tile_height
      tile = tile_at(tile_x, tile_y)
      !!tile && tile.solid?
    end

    def tile_at(x : Int32, y : Int32) : TileInfo?
      return nil if x < 0 || x >= @map_width_tiles || y < 0 || y >= @map_height_tiles
      global_gid = @map_data[y][x]
      find_tileset_and_local_id(global_gid)
    end

    # Checks for solid tiles directly below the bounding box
    def solid_down?(x : Num, y : Num, width : Num, height : Num) : Bool
      solid_at?(x.to_i, (y + height).to_i) ||
        solid_at?((x + width - 1).to_i, (y + height).to_i)
    end

    # Checks for solid tiles directly above the bounding box
    def solid_up?(x : Num, y : Num, width : Num, height : Num) : Bool
      solid_at?(x.to_i, y.to_i) ||
        solid_at?((x + width - 1).to_i, y.to_i)
    end

    # Checks for solid tiles directly to the left of the bounding box
    def solid_left?(x : Num, y : Num, width : Num, height : Num) : Bool
      solid_at?(x.to_i, y.to_i) ||
        solid_at?(x.to_i, (y + height / 2).to_i) ||
        solid_at?(x.to_i, (y + height - 1).to_i)
    end

    # Checks for solid tiles directly to the right of the bounding box
    def solid_right?(x : Num, y : Num, width : Num, height : Num) : Bool
      solid_at?((x + width).to_i, y.to_i) ||
        solid_at?((x + width).to_i, (y + height / 2).to_i) ||
        solid_at?((x + width).to_i, (y + height - 1).to_i)
    end

    # Draws the tilemap
    def draw(draw : Draw, camera_x : Int32, camera_y : Int32)
      # TODO: Implement frustum culling here
      # For simplicity, drawing all tiles for now.

      @map_data.each_with_index do |row_data, y_index|
        row_data.each_with_index do |global_gid, x_index|
          tile_info = find_tileset_and_local_id(global_gid)
          next unless tile_info

          tileset = @tilesets[tile_info.tileset_key]
          next unless tileset # Should not happen if find_tileset_and_local_id returns TileInfo

          source_rect = tileset.get_local_tile_source_rect(tile_info.local_tile_id)
          dest_rect = FRect.new(
            x: x_index * @tile_width - camera_x,
            y: y_index * @tile_height - camera_y,
            w: @tile_width,
            h: @tile_height
          )

          draw.texture(texture: tileset.texture, source_rect: source_rect, dest_rect: dest_rect)
        end
      end
    end
  end
end
