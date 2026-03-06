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

    def initialize(@name, @data, @visible = true, @opacity = 1.0_f32, @offset_x = 0, @offset_y = 0, @parallax_x = 1.0_f32, @parallax_y = 1.0_f32)
    end

    def draw(draw : Draw, tilesets : Hash(String, Tileset), tile_width : Int32, tile_height : Int32, camera : Camera? = nil, z_index : Int32 = 0)
      return unless @visible
      return if @opacity <= 0.0_f32

      camera_x = camera.try(&.x.to_f32) || 0_f32
      camera_y = camera.try(&.y.to_f32) || 0_f32

      tint = Color.new(255, 255, 255, (@opacity * 255).to_u8)

      @data.each_with_index do |row_data, y_index|
        row_data.each_with_index do |global_gid_with_flags, x_index|
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


