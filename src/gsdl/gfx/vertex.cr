module GSDL
  alias Vertices = Array(Vertex)

  def self.vertex(x : Num, y : Num, color : Color = Color::White) : Vertex
    Vertex.new(x, y, color)
  end

  struct Vertex
    @internal : SDL3::Vertex

    def self.from(point : Point, color : Color = Color::White) : Vertex
      Vertex.new(point: point, color: color)
    end

    def initialize(vertex : LibSDL3::Vertex)
      @internal = vertex
    end

    def initialize(x : Num = 0, y : Num = 0, color : Color = Color::White, texture_point = Point.new)
      @internal = SDL3::Vertex.new(x.to_f32, y.to_f32, color.to_sdl.to_fcolor, texture_point.to_sdl)
    end

    def initialize(point : Tuple(Num, Num), color : Color = Color::White)
      @internal = SDL3::Vertex.new(point[0].to_f32, point[1].to_f32, color.to_sdl.to_fcolor)
    end

    def initialize(point : Point, color : Color = Color::White, texture_point = Point.new)
      @internal = SDL3::Vertex.new(point.to_sdl, color.to_sdl.to_fcolor, texture_point.to_sdl)
    end

    def point : Point
      Point.new(@internal.fpoint)
    end

    def point=(point : Point)
      @internal.fpoint = point.to_sdl
    end

    def color : Color
      Color.new(@internal.fcolor.to_color)
    end

    def color=(color : Color)
      @internal.fcolor = color.to_sdl.to_fcolor
    end

    def distance(point : Point | Vertex) : Float32
      Point.distance(point.x - x, point.y - y)
    end

    def to_sdl
      @internal
    end

    delegate x, y, to: @internal
  end
end
