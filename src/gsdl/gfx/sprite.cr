require "./sprite_base"

class GSDL::Sprite < GSDL::SpriteBase
  @source_rect : SDL3::FRect | Nil

  def initialize(key : String, x = 0_f32, y = 0_f32, @source_rect = nil)
    super(key, x, y)
  end

  def width : Int32
    if rect = @source_rect
      rect.w.to_i
    else
      size[0].to_i
    end
  end

  def height : Int32
    if rect = @source_rect
      rect.h.to_i
    else
      size[1].to_i
    end
  end

  def draw(draw : Draw, camera_x : Float32 = 0.0_f32, camera_y : Float32 = 0.0_f32, flip_horizontal : Bool = false)
    if source_rect = @source_rect
      dest_rect = SDL3::FRect.new(
        x: x - camera_x,
        y: y - camera_y,
        w: source_rect.w,
        h: source_rect.h
      )
      draw.texture_rotated(
        texture: texture,
        source_rect: source_rect,
        dest_rect: dest_rect,
        flip: flip_horizontal ? 1 : 0
      )
    else
      draw.texture_rotated(
        texture: texture,
        x: x,
        y: y,
        flip: flip_horizontal ? 1 : 0
      )
    end
  end
end
