require "./message"

module GSDL
  class Button < Message
    alias Callback = (String)->

    getter on_click : Callback

    def initialize(
      font = Font.default,
      text : String | TextBase = "",
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
      border_radius : Num = 0,
      z_index : Int32 = 900,
      draw_relative_to_camera : Bool = false,
      @on_click : Callback = -> on_click(String),
    )
      super(
        font: font,
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
        z_index: z_index + 1,
        draw_relative_to_camera: draw_relative_to_camera,
        border_radius: border_radius
      )
    end

    def on_click(text : String)
      puts ">>> Button on_click: text: #{text}"
    end

    def update(dt : Float32)
      super

      # Use screen-space helpers for accurate mouse interaction under zoom
      if Mouse.clicked_in?(screen_x, screen_y, screen_width, screen_height)
        @on_click.call(@text.text)
      end
    end

    def draw_background(draw : Draw)
      box = Box.new(
        x: x,
        y: y,
        origin: origin,
        scale: scale,
        width: width,
        height: height,
        color: ColorScheme.get(:ui_bg),
        z_index: z_index,
        border_radius: border_radius
      )

      box.draw(draw)
    end

    def draw_border(draw : Draw)
      margin = 4
      margin_x = margin * scale_x * (1.0_f32 - 2.0_f32 * origin_x)
      margin_y = margin * scale_y * (1.0_f32 - 2.0_f32 * origin_y)

      box = Box.new(
        x: x + margin_x,
        y: y + margin_y,
        origin: origin,
        scale: scale,
        width: width - margin * 2,
        height: height - margin * 2,
        color: @text.color,
        border_radius: border_radius - margin,
        z_index: z_index,
        draw_mode: Shape::DrawMode::Outline
      )

      box.draw(draw)
    end
  end
end
