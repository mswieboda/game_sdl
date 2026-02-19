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

    def draw(draw : Draw, camera_x : Float32 = 0_f32, camera_y : Float32 = 0_f32, flip_horizontal : Bool = false)
      dest_rect = FRect.new(
        x: draw_x.to_f32 - camera_x,
        y: draw_y.to_f32 - camera_y,
        w: draw_width.to_f32,
        h: draw_height.to_f32
      )

      if source_rect = @source_rect
        draw.texture_rotated(
          texture: @texture,
          source_rect: source_rect,
          dest_rect: dest_rect,
          flip: flip_horizontal ? 1 : 0,
          z_index: z_index,
          tint: tint
        )
      else
        draw.texture_rotated(
          texture: @texture,
          dest_rect: dest_rect,
          flip: flip_horizontal ? 1 : 0,
          z_index: z_index,
          tint: tint
        )
      end
    end
  end
end
