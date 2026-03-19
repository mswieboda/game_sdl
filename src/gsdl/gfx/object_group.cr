module GSDL
  class ObjectGroup
    property name : String
    property objects : Array(TileObject)
    property visible : Bool
    property opacity : Float32
    property offset_x : Int32
    property offset_y : Int32
    property parallax_x : Float32
    property parallax_y : Float32
    property z_index : Int32 = 0
    property update_off_screen : Bool = true

    def initialize(@name, @objects = [] of TileObject, @visible = true, @opacity = 1.0_f32, @offset_x = 0, @offset_y = 0, @parallax_x = 1.0_f32, @parallax_y = 1.0_f32, @z_index = 0)
    end

    def on_screen? : Bool
      screen_w = GSDL::Game.width.to_f32
      screen_h = GSDL::Game.height.to_f32

      @objects.any? do |obj|
        obj_x = obj.x.to_f32 + @offset_x - (Game.camera.x * @parallax_x)
        obj_y = (obj.y - obj.height).to_f32 + @offset_y - (Game.camera.y * @parallax_y)
        !(obj_x + obj.width < 0 || obj_x > screen_w || obj_y + obj.height < 0 || obj_y > screen_h)
      end
    end

    def update(dt : Float32)
      return if !@update_off_screen && !on_screen?
      @objects.each(&.update(dt))
    end

    def draw(draw : Draw, tilesets : Hash(String, Tileset), tile_width : Int32, tile_height : Int32, z_index : Int32 = 0)
      return unless @visible
      return if @opacity <= 0.0_f32

      camera_x = Game.camera.x.to_f32
      camera_y = Game.camera.y.to_f32

      tint = Color.new(255, 255, 255, (@opacity * 255).to_u8)

      @objects.each do |obj|
        next unless obj.visible && (gid = obj.gid)

        tile_info = TileMap.find_tileset_and_local_id(gid, tilesets)
        next unless tile_info

        tileset = tilesets[tile_info.tileset_key]
        next unless tileset

        source_rect = tileset.get_local_tile_source_rect(tile_info.local_tile_id)

        # Tiled tile objects have origin at bottom-left
        dest_rect = FRect.new(
          x: obj.x.to_f32 + @offset_x - (camera_x * @parallax_x),
          y: (obj.y - obj.height).to_f32 + @offset_y - (camera_y * @parallax_y),
          w: obj.width,
          h: obj.height
        )

        flip_mode = 0_i32
        flip_mode |= TileMap::Flip::Horizontal if tile_info.flipped_horizontally
        flip_mode |= TileMap::Flip::Vertical if tile_info.flipped_vertically

        draw.texture_rotated(
          texture: tileset.texture,
          source_rect: source_rect,
          dest_rect: dest_rect,
          angle: obj.rotation.to_f32,
          flip: flip_mode,
          z_index: z_index,
          tint: tint
        )
      end
    end
  end
end
