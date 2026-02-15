module GSDL
  class Point < Drawable
    def to_sdl
      SDL3::FPoint.new(x: x.to_f32, y: y.to_f32)
    end

    def draw(draw : Draw)
      draw_color(draw)
      draw.point(self)
    end

    def self.draw(draw : Draw, points : Array(Point), color : Color? = nil)
      draw_color(draw, color)
      draw.points(points)
    end

    def self.draw_lines(draw : Draw, points : Array(Point), color : Color? = nil)
      draw_color(draw, color)
      draw.lines(points)
    end
  end
end
