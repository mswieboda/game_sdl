module GSDL
  class Text
    getter font
    property text
    property x : Float32
    property y : Float32
    getter color : Color

    @width : Int32?
    @surface : SDL3::Surface

    def initialize(
      @font = Font.default,
      @text = "",
      @x = 0,
      @y = 0,
      @color = GSDL::Colors::White,
      @width : Int32? = nil
    )
      width = 0

      if w = @width
        width = w
      end

      @surface = @text.empty? ? SDL3::Surface.new : font.render_text_blended_wrapped(text, color, width)
    end

    def text=(text : String)
      @text = text

      width = 0
      if w = @width
        width = w
      end

      @surface = @text.empty? ? SDL3::Surface.new : font.render_text_blended_wrapped(text, color, width)
    end

    def width
      @width || @surface.to_unsafe.value.w
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

    def draw(draw : Draw)
      return if @text.empty?

      texture = draw.create_texture(@surface)
      texture_width, texture_height = texture.size

      srcrect = FRect.new(x: 0_f32, y: 0_f32, w: texture_width, h: texture_height)
      dstrect = FRect.new(x: x.to_f32, y: y.to_f32, w: texture_width, h: texture_height)
      draw.texture(texture: texture, source_rect: srcrect, dest_rect: dstrect, destroy: true)
    end
  end
end
