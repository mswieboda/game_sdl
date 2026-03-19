module GSDL
  class TileLayer
    property name : String
    property data : Array(Array(UInt32))
    property visible : Bool
    property opacity : Float32
    property offset_x : Int32
    property offset_y : Int32
    property parallax_x : Float32
    property parallax_y : Float32
    property z_index : Int32 = 0

    def initialize(@name, @data, @visible = true, @opacity = 1.0_f32, @offset_x = 0, @offset_y = 0, @parallax_x = 1.0_f32, @parallax_y = 1.0_f32, @z_index = 0)
    end

    def draw(draw : Draw, tilesets : Hash(String, Tileset), tile_width : Int32, tile_height : Int32, z_index : Int32 = 0)
      return unless @visible
      return if @opacity <= 0.0_f32

      camera_x = Game.camera.x.to_f32
      camera_y = Game.camera.y.to_f32

      tint = Color.new(255, 255, 255, (@opacity * 255).to_u8)

      min_y = 0
      max_y = @data.size - 1
      min_x = 0
      max_x = Int32::MAX

      if draw.culling_enabled
        screen_w = GSDL::Game.width.to_f32
        screen_h = GSDL::Game.height.to_f32

        view_x = (camera_x * @parallax_x) - @offset_x
        view_y = (camera_y * @parallax_y) - @offset_y
        view_w = screen_w / draw.current_scale_x
        view_h = screen_h / draw.current_scale_y

        min_x = (view_x / tile_width).floor.to_i
        max_x = ((view_x + view_w) / tile_width).ceil.to_i
        min_y = (view_y / tile_height).floor.to_i
        max_y = ((view_y + view_h) / tile_height).ceil.to_i

        min_x = Math.max(0, min_x)
        min_y = Math.max(0, min_y)
        max_y = Math.min(@data.size - 1, max_y)
      end

      (min_y..max_y).each do |y_index|
        row_data = @data[y_index]
        row_max_x = draw.culling_enabled ? Math.min(row_data.size - 1, max_x) : row_data.size - 1
        
        next if min_x > row_max_x

        (min_x..row_max_x).each do |x_index|
          global_gid_with_flags = row_data[x_index]
          tile_info = TileMap.find_tileset_and_local_id(global_gid_with_flags, tilesets)
          next unless tile_info

          tileset = tilesets[tile_info.tileset_key]
          next unless tileset

          source_rect = tileset.get_local_tile_source_rect(tile_info.local_tile_id)

          dest_rect = FRect.new(
            x: (x_index * tile_width).to_f32 + @offset_x - (camera_x * @parallax_x),
            y: (y_index * tile_height).to_f32 + @offset_y - (camera_y * @parallax_y),
            w: tile_width.to_f32,
            h: tile_height.to_f32
          )

          flip_mode = 0_i32
          flip_mode |= TileMap::Flip::Horizontal if tile_info.flipped_horizontally
          flip_mode |= TileMap::Flip::Vertical if tile_info.flipped_vertically

          draw.texture(
            texture: tileset.texture,
            source_rect: source_rect,
            dest_rect: dest_rect,
            flip: flip_mode,
            z_index: z_index,
            tint: tint
          )
        end
      end
    end
  end
end


