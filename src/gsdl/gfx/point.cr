module GSDL
  alias Points = Array(Point)

  struct Point
    @internal : SDL3::FPoint

    def x : Float32
      @internal.x
    end

    def x=(value : Float32)
      @internal.x = value
    end

    def y : Float32
      @internal.y
    end

    def y=(value : Float32)
      @internal.y = value
    end

    def self.distance(dx : Num, dy : Num) : Float32
      Math.hypot(dx.to_f32, dy.to_f32)
    end

    def self.from(vertex : Vertex)
      Point.new(fpoint: vertex.point.to_sdl)
    end

    def initialize(fpoint : SDL3::FPoint)
      @internal = fpoint
    end

    def initialize(x : Num = 0, y : Num = 0)
      @internal = SDL3::FPoint.new(x: x.to_f32, y: y.to_f32)
    end

    def initialize(point : Tuple(Num, Num))
      @internal = SDL3::FPoint.new(x: point[0].to_f32, y: point[1].to_f32)
    end

    def distance(point : Point | Vertex) : Float32
      Point.distance(point.x - x, point.y - y)
    end

    def dot(other : Point) : Float32
      x * other.x + y * other.y
    end

    def *(scalar : Num) : Point
      Point.new(x * scalar, y * scalar)
    end

    def +(other : Point) : Point
      Point.new(x + other.x, y + other.y)
    end

    def -(other : Point) : Point
      Point.new(x - other.x, y - other.y)
    end

    def length_squared : Float32
      x * x + y * y
    end

    def length : Float32
      Math.sqrt(length_squared)
    end

    def normalize : Point
      l = length
      return Point.new(0, 0) if l == 0
      Point.new(x / l, y / l)
    end

    def to_sdl
      @internal
    end
  end
end
