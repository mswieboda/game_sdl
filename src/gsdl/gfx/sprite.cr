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

  def draw(renderer : Renderer)
    if source_rect = @source_rect
      dest_rect = SDL3::FRect.new(x: x.to_f32, y: y.to_f32, w: source_rect.w, h: source_rect.h)
      renderer.render_texture(texture: texture, source_rect: source_rect, dest_rect: dest_rect)
    else
      renderer.render_texture(texture: texture, x: x, y: y)
    end
  end
end
