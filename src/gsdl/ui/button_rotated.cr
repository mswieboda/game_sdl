require "./message_rotated"

module GSDL
  class ButtonRotated < MessageRotated
    alias Callback = (String)->

    getter on_click : Callback

    def initialize(
      font = Font.default,
      text : String = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = nil,
      height : Int32? = nil,
      padding = TextBoxRotated::Padding,
      align = Font::Align::Center,
      x : Num = 0_f32,
      y : Num = 0_f32,
      color = Color::Black,
      rotation : Num = 0.0,
      border_radius : Num = 0,
      @on_click : Callback = -> on_click(String),
      z_index : Int32 = 900
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
        rotation: rotation,
        border_radius: border_radius,
        z_index: z_index
      )
    end

    def on_click(text : String)
      puts ">>> ButtonRotated on_click: text: #{text}"
    end

    def in_rotated_rect?(mx : Num, my : Num) : Bool
      dx = mx.to_f64 - x.to_f64
      dy = my.to_f64 - y.to_f64

      rad = -rotation.to_f64 * (Math::PI / 180.0)
      cos_a = Math.cos(rad)
      sin_a = Math.sin(rad)

      local_mx = x.to_f64 + dx * cos_a - dy * sin_a
      local_my = y.to_f64 + dx * sin_a + dy * cos_a

      local_mx >= draw_x && local_mx <= draw_x + draw_width &&
        local_my >= draw_y && local_my <= draw_y + draw_height
    end

    def update(dt : Float32)
      super

      if Mouse.just_pressed?(Mouse::ButtonLeft) && in_rotated_rect?(Mouse.x, Mouse.y)
        @on_click.call(@text.text)
      end
    end

    def draw_border(draw : Draw)
      margin = 4
      margin_x = margin * scale_x * (1.0_f32 - 2.0_f32 * origin_x)
      margin_y = margin * scale_y * (1.0_f32 - 2.0_f32 * origin_y)

      rad = rotation.to_f64 * (Math::PI / 180.0)
      cos_a = Math.cos(rad)
      sin_a = Math.sin(rad)

      rot_margin_x = margin_x * cos_a - margin_y * sin_a
      rot_margin_y = margin_x * sin_a + margin_y * cos_a

      box = Box.new(
        x: x + rot_margin_x,
        y: y + rot_margin_y,
        origin: origin,
        scale: scale,
        rotation: rotation,
        width: width - margin * 2,
        height: height - margin * 2,
        color: @text.color,
        border_radius: border_radius - margin,
        draw_mode: Shape::DrawMode::Outline,
        z_index: z_index
      )

      box.draw(draw)
    end
  end
end
