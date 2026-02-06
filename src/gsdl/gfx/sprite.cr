module GSDL
  class Sprite
    property x : Float32
    property y : Float32
    getter texture : SDL3::Texture

    @key : String

    delegate size, to: @texture

    def initialize(@key, @x = 0_f32, @y = 0_f32)
      @texture = TextureManager.get(@key)
    end

    def width : Float32
      size[0]
    end

    def height : Float32
      size[1]
    end

    def center(width : Int32 | Float32, height : Int32 | Float32)
      @x = (width - self.width) // 2
      @y = (height - self.height) // 2
    end

    def draw(renderer : SDL3::Renderer)
      renderer.render_texture(texture: texture, x: x, y: y)
    end
  end
end
