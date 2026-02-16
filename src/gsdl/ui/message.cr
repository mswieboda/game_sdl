module GSDL
  class Message
    # TODO: move to variable or at least in constructor?
    Padding = 16

    getter width : Int32
    getter height : Int32
    getter padding : Int32

    @text : Text

    # TODO: width, height
    def initialize(
      font = Font.default,
      text : String = "",
      @width = 256,
      height : Int32? = nil,
      @padding = Padding,
      x : Float32 = 0_f32,
      y : Float32 = 0_f32,
      color = Colors::Green
    )
      @text = Text.new(
        font: font,
        text: text,
        color: color,
        wrap_width: width - padding * 2
      )

      if h = height
        @height = h
      else
        @height = @text.height
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
      rect = Rect.new(x: x, y: y, width: width, height: height, color: Colors::White)
      rect.draw_filled(draw)
    end

    def draw_border(draw : Draw)
      [2, 4, 6].each_with_index do |margin, i|
        rect = Rect.new(
          x: x + margin,
          y: y + margin,
          width: (width - padding / 2).to_f32,
          height: (height - padding / 2).to_f32,
          color: Colors::Red
        )
        rect.draw_outline(draw)
      end
    end

    def draw(draw : Draw)
      draw_background(draw)
      draw_border(draw)

      @text.draw
    end
  end
end