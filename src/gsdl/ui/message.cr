require "./text_box"

module GSDL
  class Message < TextBox
    def init
    end

    def draw_background(draw : Draw)
      rect = Rect.new(x: x, y: y, width: width, height: height, color: Color::White)
      rect.draw_filled(draw)
    end

    def draw_border(draw : Draw)
      [2, 4, 6].each_with_index do |margin, i|
        rect = Rect.new(
          x: x + margin,
          y: y + margin,
          width: (width - padding / 2).to_f32,
          height: (height - padding / 2).to_f32,
          color: @text.color
        )
        rect.draw_outline(draw)
      end
    end
  end
end
