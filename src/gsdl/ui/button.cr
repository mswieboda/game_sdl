require "./message"

module GSDL
  class Button < Message
    alias Callback = (String)->

    getter on_click : Callback

    def initialize(
      font = Font.default,
      text : String = "",
      width : Int32? = nil,
      height : Int32? = nil,
      padding = TextBox::Padding,
      align = Font::Align::Center,
      x : Float32 = 0_f32,
      y : Float32 = 0_f32,
      color = Color::Black,
      border_radius : UInt32 = 0,
      @on_click : Callback = Proc.new,
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
        color: color,
        border_radius: border_radius
      )
    end

    def update(dt : Float32)
      super

      if Mouse.clicked_in?(x, y, width, height)
        @on_click.call(@text.text)
      end
    end

    def draw_background(draw : Draw)
      box = Box.new(x: x, y: y, width: width, height: height, color: Color::White, border_radius: border_radius)
      box.draw_filled(draw)
    end

    def draw_border(draw : Draw)
      return if border_radius > 0

      margin = 2

      box = Box.new(
        x: x + margin,
        y: y + margin,
        width: width - margin * 2,
        height: height - margin * 2,
        color: @text.color
      )
      box.draw_outline(draw)
    end
  end
end
