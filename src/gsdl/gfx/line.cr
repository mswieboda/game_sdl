module GSDL
  class Line < Drawable
    alias Num = Int32 | Float32

    property x2 : Num
    property y2 : Num

    def initialize(x1, y1, @x2 : Num, @y2 : Num, color : Color)
      super(x: x1, y: y1, color: color)
    end

    def x1 : Num
      x
    end

    def x1=(x1 : Num)
      self.x = x1
    end

    def y1 : Num
      y
    end

    def y1=(y1 : Num) : Num
      self.y = y1
    end

    def distance
      Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2))
    end

    def draw(draw : Draw)
      draw.color = color
      draw.line(self)
    end

    def self.draw(draw : Draw, points : Array(Point))
      draw.color = points.first.color
      draw.lines(points)
    end
  end
end
