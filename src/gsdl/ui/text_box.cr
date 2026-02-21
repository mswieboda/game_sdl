module GSDL
  class TextBox
    Padding = 16

    getter width : Int32
    getter height : Int32
    getter padding : Int32

    @text : Text

    delegate origin, to: @text
    delegate :origin=, to: @text
    delegate origin_x, to: @text
    delegate :origin_x=, to: @text
    delegate origin_y, to: @text
    delegate :origin_y=, to: @text
    delegate scale, to: @text
    delegate :scale=, to: @text
    delegate scale_x, to: @text
    delegate :scale_x=, to: @text
    delegate scale_y, to: @text
    delegate :scale_y=, to: @text

    def initialize(
      font = Font.default,
      text : String = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = nil,
      height : Int32? = nil,
      @padding = Padding,
      align = Font::Align::Left,
      x : Num = 0_f32,
      y : Num = 0_f32,
      color = Color::Black
    )
      @text = Text.new(
        font: font,
        text: text,
        origin: origin,
        scale: scale,
        color: color,
        align: align,
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

    def text=(text : String)
      @text.text = text
    end

    def x
      @text.x - padding
    end

    def x=(x : Num)
      @text.x = x + padding
    end

    def y
      @text.y - padding
    end

    def y=(y : Num)
      @text.y = y + padding
    end

    def center(x : Num = 0, y : Num = 0, width : Num = 1, height : Num = 1)
      @text.center(x: x, width: width, height: height)
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
