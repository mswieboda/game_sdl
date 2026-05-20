require "./text_box"

module GSDL
  class Message < TextBox
    getter border_radius : Num
    getter bg_color : Color

    def initialize(
      font : String | Font = FontAtlasManager.default,
      font_size : Num = FontAtlasManager.default_size,
      text : String | GSDL::Text | GSDL::TextOld = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = nil,
      height : Int32? = nil,
      padding = nil,
      padding_x = nil,
      padding_y = nil,
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
        font_size: font_size,
        text: text,
        origin: origin,
        scale: scale,
        width: width,
        height: height,
        padding: padding,
        padding_x: padding_x,
        padding_y: padding_y,
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
        z_index: z_index - 1
      )
      box.draw_relative_to_camera = self.draw_relative_to_camera?
      box.draw(draw)
    end
  end
end
