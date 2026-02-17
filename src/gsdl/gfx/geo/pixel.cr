require "./point"

module GSDL
  class Pixel < Point
    property color : Color = Color::White

    def initialize(@color = Color::White)
      super()
    end

    def initialize(x, y, @color = Color::White)
      super(x: x, y: y)
    end

    def to_point
      Point.new(x: x, y: y)
    end

    def to_fpoint
      FPoint.new(x: x.to_f32, y: y.to_f32)
    end

    def draw(draw : Draw)
      draw.color = color
      draw.pixel(self)
    end

    def self.draw(draw : Draw, pixels : Array(Pixel))
      draw.color = pixels.first.color
      draw.pixels(pixels)
    end

    def self.draw_lines(draw : Draw, pixels : Array(Pixel))
      draw.color = pixels.first.color
      draw.lines(pixels)
    end
  end
end
