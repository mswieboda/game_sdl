module GSDL
  alias Vertex = SDL3::Vertex
  alias Vertices = Array(Vertex)

  def self.vertex(x : Num, y : Num, color : Color = Color::White) : Vertex
    Vertex.new(x: x.to_f32, y: y.to_f32, color: color)
  end
end

struct LibSDL3::Vertex
  def self.from(fpoint : LibSDL3::FPoint, fcolor : LibSDL3::Color = GSDL::Color::White) : LibSDL3::Vertex
    LibSDL3::Vertex.new(fpoint: fpoint, fcolor: fcolor)
  end

  def x : Float32
    @fpoint.x
  end

  def y : Float32
    @fpoint.y
  end

  def distance(point : LibSDL3::FPoint | LibSDL3::Vertex) : Float32
    Math.hypot((point.x - x).to_f32, (point.y - y).to_f32)
  end
end
