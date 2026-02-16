module GSDL
  abstract class TextBox
    Padding = 16

    getter width : Int32
    getter height : Int32
    getter padding : Int32

    @text : Text

    def initialize(
      font = Font.default,
      text : String = "",
      width : Int32? = nil,
      height : Int32? = nil,
      @padding = Padding,
      align = Font::Align::Left,
      x : Float32 = 0_f32,
      y : Float32 = 0_f32,
      color = Colors::Black
    )
      if font.align != align
        font = font.copy
        font.align = align
      end

      @text = Text.new(
        font: font,
        text: text,
        color: color,
        wrap_width: width ? width - padding * 2 : 0
      )

      @text.wrap_whitespace_visible = true

      if w = width
        @width = w
      else
        @width = @text.width + padding * 2
      end

      if h = height
        @height = h
      else
        @height = @text.height + padding * 2
      end

      @text.x = x + padding
      @text.y = y + padding
    end

    def x
      @text.x - padding
    end

    def x=(x : Float32)
      @text.x = x + padding
    end

    def y
      @text.y - padding
    end

    def y=(y : Float32)
      @text.y = y + padding
    end

    def update(dt : Float32)
      @text.update(dt)
    end

    def draw_background(draw : Draw)
    end

    def draw_border(draw : Draw)
    end

    def draw(draw : Draw)
      draw_background(draw)
      draw_border(draw)

      @text.draw(draw)
    end
  end
end
