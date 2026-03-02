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

    def to_sdl
      @internal
    end
  end
end
