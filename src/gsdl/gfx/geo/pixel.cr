require "./point"

module GSDL
  class Pixel < Point
    property color : Color = Color::White
    property z_index : Int32 = 0

    def initialize(@color = Color::White, @z_index = 0)
      super()
    end

    def initialize(x : Num, y : Num, @color = Color::White, @z_index = 0)
      super(x: x, y: y)
    end

    def initialize(point : Tuple(Num, Num), @color = Color::White, @z_index = 0)
      super(point: point)
    end

    def to_point
      Point.new(x: x, y: y)
    end

    def to_fpoint
      FPoint.new(x: x.to_f32, y: y.to_f32)
    end

    def draw(draw : Draw)
      draw.pixel(self)
    end
  end
end
