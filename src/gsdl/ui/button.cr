require "./message"

module GSDL
  class Button < Message
    def draw_background(draw : Draw)
      rect = Rect.new(x: x, y: y, width: width, height: height, color: Colors::White)
      rect.draw_filled(draw)
    end

    def draw_border(draw : Draw)
      border_margin = 2

      rect = Rect.new(
        x: x + border_margin,
        y: y + border_margin,
        width: (width - padding / 2 - border_margin).to_f32,
        height: (height - padding / 2 - border_margin).to_f32,
        color: Colors::Red
      )
      rect.draw_outline(draw)
    end

    def draw(draw : Draw)
      draw_background(draw)
      draw_border(draw)

      @text.draw
    end
  end
end
