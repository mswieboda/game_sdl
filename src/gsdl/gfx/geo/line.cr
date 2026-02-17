require "./pixel"

module GSDL
  class Line < Pixel
    property x2 : Num = 0
    property y2 : Num = 0

    def initialize(@x2 : Num = 0, @y2 : Num = 0)
      super()
    end

    def initialize(p2 : Tuple(Num, Num))
      super()

      @x2, @y2 = point
    end

    def initialize(x1, y1, @x2 : Num = 0, @y2 : Num = 0, color : Color = Color::White)
      super(x: x1, y: y1, color: color)
    end

    def initialize(p1 : Tuple(Num, Num), p2 : Tuple(Num, Num), color : Color = Color::White)
      x1, y1 = p1

      super(x: x1, y: y1, color: color)

      @x2, @y2 = p2
    end

    def initialize(points : Tuple(Num, Num, Num, Num), color : Color = Color::White)
      x1, y1, x2, y2 = points

      super(x: x1, y: y1, color: color)

      @x2 = x2
      @y2 = y2
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

    def dx
      x2 - x1
    end

    def dy
      y2 - y1
    end

    def distance
      Math.sqrt(Math.pow(dx, 2) + Math.pow(dy, 2))
    end

    def draw(draw : Draw)
      draw.color = color
      draw.line(self)
    end

    def self.draw(draw : Draw, pixels : Array(Pixel))
      draw.color = pixels.first.color
      draw.lines(pixels)
    end
  end
end
