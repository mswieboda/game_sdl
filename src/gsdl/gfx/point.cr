module GSDL
  alias FPoint = SDL3::FPoint

  class Point < Drawable
    def to_sdl
      SDL3::FPoint.new(x: x.to_f32, y: y.to_f32)
    end

    def draw(draw : Draw)
      draw.color = color
      draw.point(self)
    end

    def self.draw(draw : Draw, points : Array(Point))
      draw.color = points.first.color
      draw.points(points)
    end

    def self.draw_lines(draw : Draw, points : Array(Point))
      draw.color = points.first.color
      draw.lines(points)
    end
  end
end
