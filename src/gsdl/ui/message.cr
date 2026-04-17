require "./text_box"

module GSDL
  class Message < TextBox
    getter border_radius : Num
    getter bg_color : Color

    def initialize(
      font = Font.default,
      text : String | TextBase = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = nil,
      height : Int32? = nil,
      padding = TextBox::Padding,
      align = Font::Align::Center,
      x : Num = 0_f32,
      y : Num = 0_f32,
      color = ColorScheme.get(:ui_text),
      @bg_color : Color = ColorScheme.get(:ui_bg),
      @border_radius : Num = 0,
      z_index : Int32 = 900,
      draw_relative_to_camera : Bool = false
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
        color: color,
        z_index: z_index,
        draw_relative_to_camera: draw_relative_to_camera
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
        color: bg_color,
        border_radius: border_radius,
        z_index: z_index
      )
      box.draw_relative_to_camera = self.draw_relative_to_camera?
      box.draw(draw)
    end
  end
end
