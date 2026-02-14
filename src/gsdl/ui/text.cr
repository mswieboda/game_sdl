require "./font"

module GSDL
  class Text
    getter font
    property text
    property x : Float32
    property y : Float32
    getter color : Color

    @surface : SDL3::Surface

    def initialize(
      @font = Font.default,
      @text = "",
      @x = 0,
      @y = 0,
      @color = GSDL::Colors::White
    )

      @surface = font.render_text_blended(text, color)
    end

    def text=(text : String)
      @text = text
      @surface = font.render_text_blended(text, color)
    end

    def width
      @surface.to_unsafe.value.w
    end

    def height
      @surface.to_unsafe.value.h
    end

    def center(width : Int32 | Float32, height : Int32 | Float32)
      @x = ((width - self.width) / 2).to_f32
      @y = ((height - self.height) / 2).to_f32
    end

    def update(dt : Float32)
    end

    def draw(renderer : Renderer)
      texture = renderer.texture_from_surface(@surface)
      texture_width, texture_height = texture.size

      srcrect = FRect.new(x: 0_f32, y: 0_f32, w: texture_width, h: texture_height)
      dstrect = FRect.new(x: x.to_f32, y: y.to_f32, w: texture_width, h: texture_height)

      renderer.render_texture(texture, srcrect, dstrect)
      texture.destroy
    end
  end
end
