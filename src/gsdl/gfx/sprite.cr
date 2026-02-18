require "./sprite_base"

module GSDL
  class Sprite < SpriteBase
    @source_rect : FRect | Nil

    def initialize(key : String, x = 0, y = 0, origin = {0_f32, 0_f32}, @source_rect = nil)
      super(key: key, x: x, y: y, origin: origin)
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

    def draw(draw : Draw, camera_x : Float32 = 0.0_f32, camera_y : Float32 = 0.0_f32, flip_horizontal : Bool = false)
      if source_rect = @source_rect
        dest_rect = FRect.new(
          x: draw_x - camera_x,
          y: draw_y - camera_y,
          w: source_rect.w,
          h: source_rect.h
        )
        draw.texture_rotated(
          texture: @texture,
          source_rect: source_rect,
          dest_rect: dest_rect,
          flip: flip_horizontal ? 1 : 0,
          z_index: z_index,
          color: color
        )
      else
        draw.texture_rotated(
          texture: @texture,
          x: draw_x,
          y: draw_y,
          flip: flip_horizontal ? 1 : 0,
          z_index: z_index,
          color: color
        )
      end
    end
  end
end
