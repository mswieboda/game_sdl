require "./text_box"

module GSDL
  class Message < TextBox
    getter border_radius : Num

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
      @border_radius : Num = 0,
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
    end

    def draw_background(draw : Draw)
      box = Box.new(x: x, y: y, width: width, height: height, color: Color::White, border_radius: border_radius)
      box.draw(draw)
    end

    def draw_border(draw : Draw)
      return if border_radius > 0

      [2, 4, 6].each_with_index do |margin, i|
        box = Box.new(
          x: x + margin,
          y: y + margin,
          width: (width - padding / 2).to_f32,
          height: (height - padding / 2).to_f32,
          color: @text.color,
          draw_mode: Shape::DrawMode::Outline
        )
        box.draw(draw)
      end
    end
  end
end
