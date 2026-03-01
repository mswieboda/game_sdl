require "./text_box"

module GSDL
  class Message < TextBox
    getter border_radius : Num

    def initialize(
      font = Font.default,
      text : String = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = nil,
      height : Int32? = nil,
      padding = TextBox::Padding,
      align = Font::Align::Center,
      x : Num = 0_f32,
      y : Num = 0_f32,
      color = Color::Black,
      @border_radius : Num = 0,
      z_index : Int32 = 1000,
    )
      super(
        font: font,
        text: text,
        origin: origin,
        scale: scale,
        width: width,
        height: height,
        padding: padding,
        align: align,
        x: x,
        y: y,
        color: color
      )
    end

    def draw_background(draw : Draw)
      box = Box.new(
        x: x,
        y: y,
        origin: origin,
        scale: scale,
        width: width,
        height: height,
        color: Color::White,
        border_radius: border_radius,
        z_index: z_index
      )
      box.draw(draw)
    end
  end
end
