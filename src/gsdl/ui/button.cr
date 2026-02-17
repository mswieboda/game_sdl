require "./text_box"

module GSDL
  class Button < TextBox
    alias Callback = (String)->

    @on_click : Callback

    def initialize(
      @on_click : Callback,
      font = Font.default,
      text : String = "",
      width : Int32? = nil,
      height : Int32? = nil,
      padding = TextBox::Padding,
      align = Font::Align::Center,
      x : Float32 = 0_f32,
      y : Float32 = 0_f32,
      color = Color::Black,
    )
      super(
        font: font,
        text: text,
        width: width,
        height: height,
        padding: padding,
        align: align,
        x: x,
        y: y,
        color: color
      )

      # TODO: add on_click callback
    end

    def update(dt : Float32)
      super

      if Mouse.clicked_in?(x, y, width, height)
        @on_click.call(@text.text)
      end
    end

    def draw_background(draw : Draw)
      rect = Rect.new(x: x, y: y, width: width, height: height, color: Color::White)
      rect.draw_filled(draw)
    end

    def draw_border(draw : Draw)
      margin = 2

      rect = Rect.new(
        x: x + margin,
        y: y + margin,
        width: width - margin * 2,
        height: height - margin * 2,
        color: @text.color
      )
      rect.draw_outline(draw)
    end
  end
end
