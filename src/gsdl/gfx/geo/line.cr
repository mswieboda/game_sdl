require "./shape"

module GSDL
  class Line < Shape
    property x2 : Num = 0
    property y2 : Num = 0

    def initialize(x1, y1, @x2 : Num, @y2 : Num)
      super(x: x1, y: y1)
    end

    def initialize(@x2 : Num, @y2 : Num)
      super()
    end

    def initialize(x1, y1, @x2 : Num, @y2 : Num, color : Color)
      super(x: x1, y: y1, color: color)
    end

    # not used for this class, can just use raw values to draw
    def update_geometry
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
