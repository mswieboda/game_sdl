require "json"
require "xml"

module GSDL
  alias MapLayer = TileLayer | ObjectGroup

  class TileMap
    # Bits on the far end of the 32-bit global tile ID are used for tile flags
    FLIPPED_HORIZONTALLY_FLAG  = 0x80000000_u32
    FLIPPED_VERTICALLY_FLAG    = 0x40000000_u32
    FLIPPED_DIAGONALLY_FLAG    = 0x20000000_u32 # Tiled's diagonal flip flag
    ALL_FLIP_FLAGS             = FLIPPED_HORIZONTALLY_FLAG | FLIPPED_VERTICALLY_FLAG | FLIPPED_DIAGONALLY_FLAG

    module Flip
      Horizontal = 0x00000001_i32 # SDL_FLIP_HORIZONTAL
      Vertical = 0x00000002_i32 # SDL_FLIP_VERTICAL
      None = 0x00000000_i32 # SDL_FLIP_NONE
    end

    # Collection of MapLayers (TileLayer or ObjectGroup)
    property layers : Array(MapLayer)
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
      @layers = [] of MapLayer
      @tilesets = {} of String => Tileset
      @map_width_tiles = 0
      @map_height_tiles = 0
      @tiled_tilesets = [] of JSON::Any
    end

    # Returns all objects across all object layers
    def objects : Array(TileObject)
      all_objects = [] of TileObject
      @layers.each do |layer|
        if layer.is_a?(ObjectGroup)
          all_objects.concat(layer.objects)
        end
      end
      all_objects
    end

    def get_objects_at(px : Float32, py : Float32) : Array(TileObject)
      objects.select(&.contains?(px, py))
    end

    def get_objects_in(rect : FRect) : Array(TileObject)
      objects.select { |obj| rect.overlaps?(obj.get_collision_rect) }
    end

    def update(dt : Float32)
      @layers.each do |layer|
        if layer.is_a?(ObjectGroup)
          layer.update(dt)
        end
      end
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

        texture = GSDL::TextureManager.get_texture_by_name(name) || raise "Asset Registry Error: Tileset name '#{name}' is not registered in TextureManager!"

        tileset = GSDL::Tileset.new(
          texture,
          ts_data["tilewidth"].as_i,
          ts_data["tileheight"].as_i,
          ts_data["firstgid"].as_i
        )

        if ts_data["properties"]? && (props_json = ts_data["properties"]).as_a?
          props_json.as_a.each do |prop|
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

      json["layers"].as_a.each_with_index do |layer_json, index|
        type = layer_json["type"].as_s
        layer_name = layer_json["name"]? ? layer_json["name"].as_s : "layer_#{index}"
        visible = layer_json["visible"]? ? layer_json["visible"].as_bool : true
        opacity = layer_json["opacity"]? ? (layer_json["opacity"].as_f? || layer_json["opacity"].as_i.to_f32).to_f32 : 1.0_f32
        offset_x = layer_json["offsetx"]? ? layer_json["offsetx"].as_i : 0
        offset_y = layer_json["offsety"]? ? layer_json["offsety"].as_i : 0
        parallax_x = layer_json["parallaxx"]? ? (layer_json["parallaxx"].as_f? || layer_json["parallaxx"].as_i.to_f32).to_f32 : 1.0_f32
        parallax_y = layer_json["parallaxy"]? ? (layer_json["parallaxy"].as_f? || layer_json["parallaxy"].as_i.to_f32).to_f32 : 1.0_f32

        # Determine z_index based on order in file (bottom layers first)
        # We start from 0 and increment.
        layer_z = index

        case type
        when "tilelayer"
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
            parallax_y: parallax_y,
            z_index: layer_z
          )
          tile_map.layers << layer
        when "objectgroup"
          objects = [] of TileObject
          if objs_json = layer_json["objects"]?.try(&.as_a)
            objs_json.each do |obj_json|
              id = obj_json["id"].as_i
              name = obj_json["name"]? ? obj_json["name"].as_s : ""
              # Tiled 1.9+ uses "class" instead of "type"
              obj_type = (obj_json["type"]? || obj_json["class"]? || JSON::Any.new("")).as_s
              x = (obj_json["x"].as_f? || obj_json["x"].as_i.to_f32).to_f32
              y = (obj_json["y"].as_f? || obj_json["y"].as_i.to_f32).to_f32
              width = (obj_json["width"]? ? (obj_json["width"].as_f? || obj_json["width"].as_i.to_f32).to_f32 : 0_f32)
              height = (obj_json["height"]? ? (obj_json["height"].as_f? || obj_json["height"].as_i.to_f32).to_f32 : 0_f32)
              rotation = (obj_json["rotation"]? ? (obj_json["rotation"].as_f? || obj_json["rotation"].as_i.to_f32).to_f32 : 0_f32)
              obj_visible = obj_json["visible"]? ? obj_json["visible"].as_bool : true
              gid = obj_json["gid"]?.try(&.as_i.to_u32)

              properties = {} of String => JSON::Any
              if props = obj_json["properties"]?.try(&.as_a)
                props.each do |prop|
                  properties[prop["name"].as_s] = prop["value"]
                end
              end

              objects << TileObjectFactory.create(
                id: id,
                name: name,
                type: obj_type,
                x: x,
                y: y,
                width: width,
                height: height,
                rotation: rotation,
                visible: obj_visible,
                gid: gid,
                properties: properties
              )
            end
          end

          group = ObjectGroup.new(
            name: layer_name,
            objects: objects,
            visible: visible,
            opacity: opacity,
            offset_x: offset_x,
            offset_y: offset_y,
            parallax_x: parallax_x,
            parallax_y: parallax_y,
            z_index: layer_z
          )
          tile_map.layers << group
        end
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

      layer_count = 0
      map_node.children.each do |node|
        case node.name
        when "tileset"
          name = node["name"]
          firstgid = node["firstgid"].to_i
          ts_tile_w = node["tilewidth"].to_i
          ts_tile_h = node["tileheight"].to_i

          texture = GSDL::TextureManager.get_texture_by_name(name) || raise "Asset Registry Error: Tileset name '#{name}' is not registered in TextureManager!"
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
          layer_name = node["name"]? || "layer_#{layer_count}"
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
                parallax_y: parallax_y,
                z_index: layer_count
              )
              tile_map.layers << layer
              layer_count += 1
            else
              raise "Unsupported TMX encoding: #{encoding || "none"}. Only CSV is supported for now."
            end
          end
        when "objectgroup"
          layer_name = node["name"]? || "layer_#{layer_count}"
          visible = node["visible"]? != "0"
          opacity = node["opacity"]?.try(&.to_f32) || 1.0_f32
          offset_x = node["offsetx"]?.try(&.to_i) || 0
          offset_y = node["offsety"]?.try(&.to_i) || 0
          parallax_x = node["parallaxx"]?.try(&.to_f32) || 1.0_f32
          parallax_y = node["parallaxy"]?.try(&.to_f32) || 1.0_f32

          objects = [] of TileObject
          node.children.each do |obj_node|
            next unless obj_node.name == "object"
            id = obj_node["id"].to_i
            name = obj_node["name"]? || ""
            obj_type = obj_node["type"]? || obj_node["class"]? || ""
            x = obj_node["x"].to_f32
            y = obj_node["y"].to_f32
            width = obj_node["width"]?.try(&.to_f32) || 0_f32
            height = obj_node["height"]?.try(&.to_f32) || 0_f32
            rotation = obj_node["rotation"]?.try(&.to_f32) || 0_f32
            obj_visible = obj_node["visible"]? != "0"
            gid = obj_node["gid"]?.try(&.to_u32)

            properties = {} of String => JSON::Any
            props_node = obj_node.children.find { |n| n.name == "properties" }
            if props_node
              props_node.children.each do |prop|
                next unless prop.name == "property"
                val = prop["value"]
                if val == "true"
                  properties[prop["name"]] = JSON::Any.new(true)
                elsif val == "false"
                  properties[prop["name"]] = JSON::Any.new(false)
                elsif i_val = val.to_i?
                  properties[prop["name"]] = JSON::Any.new(i_val.to_i64)
                elsif f_val = val.to_f?
                  properties[prop["name"]] = JSON::Any.new(f_val.to_f64)
                else
                  properties[prop["name"]] = JSON::Any.new(val)
                end
              end
            end

            objects << TileObjectFactory.create(
              id: id,
              name: name,
              type: obj_type,
              x: x,
              y: y,
              width: width,
              height: height,
              rotation: rotation,
              visible: obj_visible,
              gid: gid,
              properties: properties
            )
          end

          group = ObjectGroup.new(
            name: layer_name,
            objects: objects,
            visible: visible,
            opacity: opacity,
            offset_x: offset_x,
            offset_y: offset_y,
            parallax_x: parallax_x,
            parallax_y: parallax_y,
            z_index: layer_count
          )
          tile_map.layers << group
          layer_count += 1
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
      ] of ObjectGroup | TileLayer
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

        if layer.is_a?(TileLayer)
          return false if tile_x < 0 || tile_x >= @map_width_tiles || tile_y < 0 || tile_y >= @map_height_tiles

          global_gid_with_flags = layer.data[tile_y][tile_x]
          tile_info = find_tileset_and_local_id(global_gid_with_flags)
          return true if tile_info && tile_info.solid?
        elsif layer.is_a?(ObjectGroup)
          layer.objects.each do |obj|
            next unless obj.visible && (gid = obj.gid)
            if obj.contains?(x.to_f32, y.to_f32)
              tile_info = find_tileset_and_local_id(gid)
              return true if tile_info && tile_info.solid?
            end
          end
        end
      end

      false
    end

    def tile_at(x : Int32, y : Int32) : TileInfo?
      return nil if x < 0 || x >= @map_width_tiles || y < 0 || y >= @map_height_tiles

      # Return the first tile info found from top to bottom
      @layers.reverse_each do |layer|
        next unless layer.visible

        if layer.is_a?(TileLayer)
          global_gid_with_flags = layer.data[y][x]
          tile_info = find_tileset_and_local_id(global_gid_with_flags)
          return tile_info if tile_info
        elsif layer.is_a?(ObjectGroup)
          layer.objects.each do |obj|
            next unless obj.visible && (gid = obj.gid)
            if obj.contains?((x * @tile_width).to_f32, (y * @tile_height).to_f32)
              return find_tileset_and_local_id(gid)
            end
          end
        end
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
    def get_layer(name : String) : MapLayer?
      @layers.find { |l| l.name == name }
    end

    # Returns objects of a specific type (or class)
    def get_objects_by_type(type : String) : Array(TileObject)
      all_objects = [] of TileObject
      @layers.each do |layer|
        if layer.is_a?(ObjectGroup)
          all_objects.concat(layer.objects.select { |o| o.type == type })
        end
      end
      all_objects
    end

    # Returns an object by name
    def get_object_by_name(name : String) : TileObject?
      @layers.each do |layer|
        if layer.is_a?(ObjectGroup)
          if obj = layer.objects.find { |o| o.name == name }
            return obj
          end
        end
      end
      nil
    end

    # Returns objects with a specific property
    def get_objects_by_property(key : String, value : JSON::Any) : Array(TileObject)
      all_objects = [] of TileObject
      @layers.each do |layer|
        if layer.is_a?(ObjectGroup)
          all_objects.concat(layer.objects.select { |o| o.properties[key]? == value })
        end
      end
      all_objects
    end

    # Sets layer visibility
    def set_layer_visibility(name : String, visible : Bool)
      if layer = get_layer(name)
        layer.visible = visible
      end
    end

    # Draws a specific layer
    def draw_layer(draw : Draw, layer_name : String)
      if layer = get_layer(layer_name)
        layer.draw(draw, @tilesets, @tile_width, @tile_height, @z_index + layer.z_index)
      end
    end

    # Draws the tilemap
    def draw(draw : Draw)
      draw.with_camera(nil) do
        old_scale_x = draw.current_scale_x
        old_scale_y = draw.current_scale_y

        draw.scale = Game.camera.zoom

        @layers.each do |layer|
          layer.draw(draw, @tilesets, @tile_width, @tile_height, @z_index + layer.z_index)
        end

        draw.scale = {old_scale_x, old_scale_y}
      end
    end
  end
end
