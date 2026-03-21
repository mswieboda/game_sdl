require "./sprite_base"

module GSDL
  class Sprite < SpriteBase
    @source_rect : FRect | Nil

    def initialize(
      key : String,
      x : Num = 0,
      y : Num = 0,
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      tint : Color? = nil,
      @source_rect = nil
    )
      super(key: key, x: x, y: y, origin: origin, scale: scale, tint: tint)
    end

    def width : Num
      if rect = @source_rect
        rect.w
      else
        size[0]
      end
    end

    def height : Num
      if rect = @source_rect
        rect.h
      else
        size[1]
      end
    end

    def update(dt : Float32)
      return unless super(dt)
    end

    def draw(draw : Draw)
      old_scale_x = draw.current_scale_x
      old_scale_y = draw.current_scale_y

      if draw_relative_to_camera?
        draw.scale = Game.camera.zoom
      end

      camera_x = draw_relative_to_camera? ? Game.camera.x : 0_f32
      camera_y = draw_relative_to_camera? ? Game.camera.y : 0_f32

      dest_rect = FRect.new(
        x: draw_x - camera_x,
        y: draw_y - camera_y,
        w: draw_width,
        h: draw_height
      )

      flip_val = 0
      flip_val |= 1 if flip_h?
      flip_val |= 2 if flip_v?

      if source_rect = @source_rect
        draw.texture_rotated(
          texture: @texture,
          source_rect: source_rect,
          dest_rect: dest_rect,
          angle: rotation,
          center: center_point_from_origin,
          flip: flip_val,
          tint: tint,
          z_index: z_index,
          sort_y: ground_y.to_f32
        )
      else
        draw.texture_rotated(
          texture: @texture,
          dest_rect: dest_rect,
          angle: rotation,
          center: center_point_from_origin,
          flip: flip_val,
          tint: tint,
          z_index: z_index,
          sort_y: ground_y.to_f32
        )
      end

      if draw_relative_to_camera?
        draw.scale = {old_scale_x, old_scale_y}
      end
    end
  end
end
