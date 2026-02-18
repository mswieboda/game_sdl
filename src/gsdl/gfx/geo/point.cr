module GSDL
  alias FPoint = SDL3::FPoint

  abstract class Point
    getter x : Num = 0
    getter y : Num = 0

    def initialize(@x : Num = 0, @y : Num = 0)
    end

    def initialize(point : Tuple(Num, Num))
      @x, @y = point
    end

    def center(width : Num, height : Num)
      @x = (width / 2).to_f32
      @y = (height / 2).to_f32
    end

    def to_fpoint
      FPoint.new(x: x.to_f32, y: y.to_f32)
    end

    abstract def draw(draw : Draw)

    def self.draw(draw : Draw, points : Array(Point))
      points.each(&.draw(draw))
    end
  end
end
