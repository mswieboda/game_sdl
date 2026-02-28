require "json"

module GSDL
  class TileMap
    # Bits on the far end of the 32-bit global tile ID are used for tile flags
    FLIPPED_HORIZONTALLY_FLAG  = 0x80000000_u32
    FLIPPED_VERTICALLY_FLAG    = 0x40000000_u32
    FLIPPED_DIAGONALLY_FLAG    = 0x20000000_u32 # Tiled's diagonal flip flag, kept for completeness but not actively used for rendering rotation as per instruction.
    ALL_FLIP_FLAGS             = FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG

    module Flip
      Horizontal = 0x00000001_i32 # SDL_FLIP_HORIZONTAL
      Vertical = 0x00000002_i32 # SDL_FLIP_VERTICAL
      None = 0x00000000_i32 # SDL_FLIP_NONE
    end

    # Using a 2D array of UInt32 to store global tile IDs and their flags.
    property map_data : Array(Array(UInt32))
    # Map of tileset key to Tileset object
    property tilesets : Hash(String, Tileset)
    property tile_width : Int32
    property tile_height : Int32
    property map_width_tiles : Int32
    property map_height_tiles : Int32
    property tiled_tilesets : Array(JSON::Any)

    def initialize(@tile_width, @tile_height)
      @map_data = [] of Array(UInt32)
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
        # Handle potential missing "image" key for tilesets that are collections of images etc.
        # For simplicity here, we assume a path exists or use a placeholder.
        image_path =
          if ts_data["image"]?
            "assets/gfx/" + ts_data["image"].as_s
          else
            # A placeholder or more complex logic might be needed for specific tileset types
            "assets/gfx/missing_image.png"
          end

        texture = GSDL::TextureManager.get(name)

        # Create and configure the tileset
        tileset = GSDL::Tileset.new(
          texture,
          ts_data["tilewidth"].as_i,
          ts_data["tileheight"].as_i,
          ts_data["firstgid"].as_i
        )

        # Look for custom properties under the "properties" key in the tileset data
        if ts_data["properties"].as_a?.is_a?(Array)
          ts_data["properties"].as_a.each do |prop|
            if prop["name"].as_s == "solid_tiles"
              # Assuming "value" holds the array of solid local tile IDs
              solid_tiles_json = prop["value"]
              if solid_tiles_json.as_a.is_a?(Array)
                tileset.solid_tiles = solid_tiles_json.as_a.map { |n| n.as_i - 1 }
              end

              break # Found solid_tiles, no need to check other properties
            end
          end
        elsif ts_data["properties"]?.is_a?(Hash)
           # Handle if properties are directly under an object, not an array
           solid_tiles_json = ts_data["properties"]["solid_tiles"]?
           if solid_tiles_json.is_a?(Array)
             tileset.solid_tiles = solid_tiles_json.as_a.map(&.as_i)
           end
        end


        tile_map.add_tileset(name, tileset)
      end

      layer_data = json["layers"][0]["data"].as_a.map(&.as_i.to_u32)
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
      @map_data = data.map { |d| d.map(&.to_u32)  }
      @map_height_tiles = data.size
      @map_width_tiles = data.empty? ? 0 : data[0].size
    end

    private def self.chunk_data(data : Array(UInt32), width : Int32) : Array(Array(UInt32))
      result = [] of Array(UInt32)
      (data.size / width).to_i.times do |i|
        start_index = i * width
        end_index = start_index + width
        result << data[start_index...end_index]
      end
      result
    end

    # Translates a global_gid into a Tileset and its local_tile_id
    def find_tileset_and_local_id(global_gid_with_flags : UInt32) : TileInfo?
      # A global_gid of 0 typically means an empty tile in Tiled
      return nil if global_gid_with_flags == 0

      flipped_horizontally = (global_gid_with_flags & FLIPPED_HORIZONTALLY_FLAG) != 0_u32
      flipped_vertically = (global_gid_with_flags & FLIPPED_VERTICALLY_FLAG) != 0_u32
      # flipped_diagonally = (global_gid_with_flags & FLIPPED_DIAGONALLY_FLAG) != 0_u32 # Ignoring for now

      # Clear all flip flags to get the actual global tile ID
      global_gid = (global_gid_with_flags & ~ALL_FLIP_FLAGS).to_i

      @tilesets.each do |key, tileset|
        if tileset.contains_gid?(global_gid)
          local_tile_id = global_gid - tileset.first_gid
          return TileInfo.new(
            key,
            local_tile_id,
            tileset.solid?(local_tile_id),
            flipped_horizontally,
            flipped_vertically
          )
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
      global_gid_with_flags = @map_data[y][x]
      find_tileset_and_local_id(global_gid_with_flags)
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
    def draw(draw : Draw, camera : Camera? = nil)
      camera_x = camera.try(&.x.to_i32) || 0
      camera_y = camera.try(&.y.to_i32) || 0

      # TODO: Implement frustum culling here
      # For simplicity, drawing all tiles for now.

      @map_data.each_with_index do |row_data, y_index|
        row_data.each_with_index do |global_gid_with_flags, x_index|
          tile_info = find_tileset_and_local_id(global_gid_with_flags)
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

          flip_mode = 0_i32
          flip_mode |= Flip::Horizontal if tile_info.flipped_horizontally
          flip_mode |= Flip::Vertical if tile_info.flipped_vertically

          draw.texture(
            texture: tileset.texture,
            source_rect: source_rect,
            dest_rect: dest_rect,
            flip: flip_mode
          )
        end
      end
    end
  end
end
