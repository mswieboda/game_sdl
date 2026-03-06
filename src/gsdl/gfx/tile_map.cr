require "json"
require "xml"

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

    # Collection of TileLayers
    property layers : Array(TileLayer)
    # Map of tileset key to Tileset object
    property tilesets : Hash(String, Tileset)
    property tile_width : Int32
    property tile_height : Int32
    property map_width_tiles : Int32
    property map_height_tiles : Int32
    property tiled_tilesets : Array(JSON::Any)
    property z_index : Int32 = 0

    def width : Int32
      @map_width_tiles * @tile_width
    end

    def height : Int32
      @map_height_tiles * @tile_height
    end

    def initialize(@tile_width, @tile_height)
      @layers = [] of TileLayer
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
        image_path =
          if ts_data["image"]?
            "assets/gfx/" + ts_data["image"].as_s
          else
            "assets/gfx/missing_image.png"
          end

        texture = GSDL::TextureManager.get(name)

        tileset = GSDL::Tileset.new(
          texture,
          ts_data["tilewidth"].as_i,
          ts_data["tileheight"].as_i,
          ts_data["firstgid"].as_i
        )

        if ts_data["properties"].as_a?.is_a?(Array)
          ts_data["properties"].as_a.each do |prop|
            if prop["name"].as_s == "solid_tiles"
              solid_tiles_json = prop["value"]
              if solid_tiles_json.as_a?.is_a?(Array)
                tileset.solid_tiles = solid_tiles_json.as_a.map { |n| n.as_i - 1 }
              elsif solid_tiles_json.as_s?.is_a?(String)
                val = solid_tiles_json.as_s
                if val.starts_with?("[") && val.ends_with?("]")
                  tileset.solid_tiles = val[1...-1].split(",").map { |v| v.strip.to_i - 1 }
                end
              end
              break
            end
          end
        elsif ts_data["properties"]?.is_a?(Hash)
           solid_tiles_json = ts_data["properties"]["solid_tiles"]?
           if solid_tiles_json.is_a?(Array)
             tileset.solid_tiles = solid_tiles_json.as_a.map(&.as_i)
           end
        end

        tile_map.add_tileset(name, tileset)
      end

      json["layers"].as_a.each do |layer_json|
        next if layer_json["type"].as_s != "tilelayer"

        layer_name = layer_json["name"].as_s
        visible = layer_json["visible"]? ? layer_json["visible"].as_bool : true
        opacity = layer_json["opacity"]? ? layer_json["opacity"].as_f.to_f32 : 1.0_f32
        offset_x = layer_json["offsetx"]? ? layer_json["offsetx"].as_i : 0
        offset_y = layer_json["offsety"]? ? layer_json["offsety"].as_i : 0
        parallax_x = layer_json["parallaxx"]? ? layer_json["parallaxx"].as_f.to_f32 : 1.0_f32
        parallax_y = layer_json["parallaxy"]? ? layer_json["parallaxy"].as_f.to_f32 : 1.0_f32

        raw_data = layer_json["data"].as_a.map(&.as_i.to_u32)
        chunked_data = chunk_data(raw_data, map_w)

        layer = TileLayer.new(
          name: layer_name,
          data: chunked_data,
          visible: visible,
          opacity: opacity,
          offset_x: offset_x,
          offset_y: offset_y,
          parallax_x: parallax_x,
          parallax_y: parallax_y
        )
        tile_map.layers << layer
      end

      tile_map
    end

    def self.from_tiled_tmx(xml_str : String) : TileMap
      xml = XML.parse(xml_str)
      map_node = xml.first_element_child
      if !map_node || map_node.name != "map"
        raise "No <map> node found in TMX"
      end

      tile_w = map_node["tilewidth"].to_i
      tile_h = map_node["tileheight"].to_i
      map_w = map_node["width"].to_i
      map_h = map_node["height"].to_i

      tile_map = TileMap.new(tile_w, tile_h)
      tile_map.map_width_tiles = map_w
      tile_map.map_height_tiles = map_h

      map_node.children.each do |node|
        case node.name
        when "tileset"
          name = node["name"]
          firstgid = node["firstgid"].to_i
          ts_tile_w = node["tilewidth"].to_i
          ts_tile_h = node["tileheight"].to_i

          texture = GSDL::TextureManager.get(name)
          tileset = GSDL::Tileset.new(texture, ts_tile_w, ts_tile_h, firstgid)

          props_node = node.children.find { |n| n.name == "properties" }
          if props_node
            props_node.children.each do |prop|
              next unless prop.name == "property"
              if prop["name"] == "solid_tiles"
                val = prop["value"]
                if val.starts_with?("[") && val.ends_with?("]")
                  tileset.solid_tiles = val[1...-1].split(",").map { |v| v.strip.to_i - 1 }
                end
              end
            end
          end

          tile_map.add_tileset(name, tileset)
        when "layer"
          layer_name = node["name"]
          visible = node["visible"]? != "0"
          opacity = node["opacity"]?.try(&.to_f32) || 1.0_f32
          offset_x = node["offsetx"]?.try(&.to_i) || 0
          offset_y = node["offsety"]?.try(&.to_i) || 0
          parallax_x = node["parallaxx"]?.try(&.to_f32) || 1.0_f32
          parallax_y = node["parallaxy"]?.try(&.to_f32) || 1.0_f32

          data_node = node.children.find { |n| n.name == "data" }
          if data_node
            encoding = data_node["encoding"]?
            if encoding == "csv"
              csv_data = data_node.content.strip
              layer_data = csv_data.split(/[\s,]+/).reject(&.empty?).map(&.to_u32)
              chunked_data = chunk_data(layer_data, map_w)

              layer = TileLayer.new(
                name: layer_name,
                data: chunked_data,
                visible: visible,
                opacity: opacity,
                offset_x: offset_x,
                offset_y: offset_y,
                parallax_x: parallax_x,
                parallax_y: parallax_y
              )
              tile_map.layers << layer
            else
              raise "Unsupported TMX encoding: #{encoding || "none"}. Only CSV is supported for now."
            end
          end
        end
      end

      tile_map
    end

    def self.from_tiled_file(filepath : String) : TileMap
      content = File.read(filepath)
      if filepath.ends_with?(".tmx") || content.strip.starts_with?("<?xml") || content.strip.starts_with?("<map")
        from_tiled_tmx(content)
      else
        from_tiled_json(JSON.parse(content))
      end
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
      chunked_data = data.map { |d| d.map(&.to_u32)  }
      @map_height_tiles = data.size
      @map_width_tiles = data.empty? ? 0 : data[0].size

      @layers = [
        TileLayer.new(
          name: "main",
          data: chunked_data
        )
      ]
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
    def self.find_tileset_and_local_id(global_gid_with_flags : UInt32, tilesets : Hash(String, Tileset)) : TileInfo?
      # A global_gid of 0 typically means an empty tile in Tiled
      return nil if global_gid_with_flags == 0

      flipped_horizontally = (global_gid_with_flags & FLIPPED_HORIZONTALLY_FLAG) != 0_u32
      flipped_vertically = (global_gid_with_flags & FLIPPED_VERTICALLY_FLAG) != 0_u32

      # Clear all flip flags to get the actual global tile ID
      global_gid = (global_gid_with_flags & ~ALL_FLIP_FLAGS).to_i

      tilesets.each do |key, tileset|
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

    def find_tileset_and_local_id(global_gid_with_flags : UInt32) : TileInfo?
      TileMap.find_tileset_and_local_id(global_gid_with_flags, @tilesets)
    end

    def solid_at?(x : Int32, y : Int32) : Bool
      tile_x = x // @tile_width
      tile_y = y // @tile_height

      # Check layers from top to bottom
      @layers.reverse_each do |layer|
        next unless layer.visible
        return false if tile_x < 0 || tile_x >= @map_width_tiles || tile_y < 0 || tile_y >= @map_height_tiles

        global_gid_with_flags = layer.data[tile_y][tile_x]
        tile_info = find_tileset_and_local_id(global_gid_with_flags)
        return true if tile_info && tile_info.solid?
      end

      false
    end

    def tile_at(x : Int32, y : Int32) : TileInfo?
      return nil if x < 0 || x >= @map_width_tiles || y < 0 || y >= @map_height_tiles

      # Return the first tile info found from top to bottom
      @layers.reverse_each do |layer|
        next unless layer.visible
        global_gid_with_flags = layer.data[y][x]
        tile_info = find_tileset_and_local_id(global_gid_with_flags)
        return tile_info if tile_info
      end

      nil
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

    # Returns a layer by name
    def get_layer(name : String) : TileLayer?
      @layers.find { |l| l.name == name }
    end

    # Sets layer visibility
    def set_layer_visibility(name : String, visible : Bool)
      if layer = get_layer(name)
        layer.visible = visible
      end
    end

    # Draws a specific layer
    def draw_layer(draw : Draw, layer_name : String, camera : Camera? = nil)
      if layer = get_layer(layer_name)
        layer.draw(draw, @tilesets, @tile_width, @tile_height, camera, @z_index)
      end
    end

    # Draws the tilemap
    def draw(draw : Draw, camera : Camera? = nil)
      old_scale_x = draw.current_scale_x
      old_scale_y = draw.current_scale_y

      if camera
        draw.scale = camera.zoom
      end

      @layers.each do |layer|
        layer.draw(draw, @tilesets, @tile_width, @tile_height, camera, @z_index)
      end

      if camera
        draw.scale = {old_scale_x, old_scale_y}
      end
    end
  end
end
