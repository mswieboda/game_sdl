require "./pixel"

module GSDL
  class Line < Pixel
    property x2 : Num = 0
    property y2 : Num = 0
    property color : Color = Color::White

    def initialize(@x2 : Num = 0, @y2 : Num = 0, @color = Color::White)
      super()
    end

    def initialize(x1, y1, @x2 : Num, @y2 : Num, @color : Color = Color::White)
      super(x: x1, y: y1)
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

    def self.draw(draw : Draw, pixels : Array(Pixel))
      draw.color = pixels.first.color
      draw.lines(pixels)
    end
  end
end
