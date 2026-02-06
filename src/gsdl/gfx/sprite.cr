module GSDL
  class Sprite
    property x : Float32
    property y : Float32
    getter texture : SDL3::Texture

    @source_rect : SDL3::FRect | Nil
    @key : String

    delegate size, to: @texture

    def initialize(@key, @x = 0_f32, @y = 0_f32, @source_rect = nil)
      @texture = TextureManager.get(@key)
    end

    def width : Float32
      if rect = @source_rect
        rect.w
      else
        size[0]
      end
    end

    def height : Float32
      if rect = @source_rect
        rect.h
      else
        size[1]
      end
    end

    def center(width : Int32 | Float32, height : Int32 | Float32)
      @x = (width - self.width) // 2
      @y = (height - self.height) // 2
    end

    def draw(renderer : SDL3::Renderer)
      if source_rect = @source_rect
        dest_rect = SDL3::FRect.new(x: x, y: y, w: source_rect.w, h: source_rect.h)
        renderer.render_texture(texture: texture, source_rect: source_rect, dest_rect: dest_rect)
      else
        renderer.render_texture(texture: texture, x: x, y: y)
      end
    end
  end
end
