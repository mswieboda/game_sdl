require "./font"

module GSDL
  class Text
    getter font
    getter text
    property x : Int32
    property y : Int32
    getter color : LibSDL3::Color
    getter? ansi

    @surface : SDL3::Surface

    def initialize(
      @font = Font.default,
      @text = "",
      @x = 0,
      @y = 0,
      @color = LibSDL3::Color.new(r: 0, g: 0, b: 0, a: 255),
      @ansi = true
    )

      @surface = font.render_text_blended(text, color)
    end

    def width
      @surface.to_unsafe.value.w
    end

    def height
      @surface.to_unsafe.value.h
    end

    def update(frame_time : Float32)
    end

    def draw(renderer : Renderer)
      texture = SDL3::Texture.from_surface(renderer, @surface)
      texture_width, texture_height = texture.size

      srcrect = LibSDL3::FRect.new(x: 0_f32, y: 0_f32, w: texture_width, h: texture_height)
      dstrect = LibSDL3::FRect.new(x: x.to_f32, y: y.to_f32, w: texture_width, h: texture_height)

      renderer.render_texture(texture, srcrect, dstrect)
      texture.destroy
    end
  end
end
