module GSDL
  alias FPoint = SDL3::FPoint
  alias Point = FPoint
  alias FPoints = Array(FPoint)
  alias Points = Array(Point)
end

struct LibSDL3::FPoint
  def initialize(x : GSDL::Num = 0, y : GSDL::Num = 0)
    @x = x.to_f32
    @y = y.to_f32
  end

  def initialize(point : Tuple(GSDL::Num, GSDL::Num) = {0, 0})
    x, y = point
    @x = x.to_f32
    @y = y.to_f32
  end

  def x : Float32
    @x
  end

  def x=(x : GSDL::Num)
    @x = x.to_f32
  end

  def x=(x : Float32)
    @x = x
  end

  def y : Float32
    @y
  end

  def y=(y : GSDL::Num)
    @y = y.to_f32
  end

  def y=(y : Float32)
    @y = y
  end

  def distance(point : LibSDL3::FPoint | Vertex) : Float32
    LibSDL3::FPoint.distance(point.x - x, point.y - y)
  end

  def dot(other : LibSDL3::FPoint) : Float32
    x * other.x + y * other.y
  end

  def *(scalar : GSDL::Num) : LibSDL3::FPoint
    LibSDL3::FPoint.new(x * scalar, y * scalar)
  end

  def +(other : LibSDL3::FPoint) : LibSDL3::FPoint
    LibSDL3::FPoint.new(x + other.x, y + other.y)
  end

  def -(other : LibSDL3::FPoint) : LibSDL3::FPoint
    LibSDL3::FPoint.new(x - other.x, y - other.y)
  end

  def length_squared : Float32
    x * x + y * y
  end

  def length : Float32
    Math.sqrt(length_squared)
  end

  def lerp(other : LibSDL3::FPoint, t : GSDL::Num) : LibSDL3::FPoint
    self + (other - self) * t.to_f32
  end

  def normalize : LibSDL3::FPoint
    l = length
    return LibSDL3::FPoint.new(0, 0) if l == 0
    self * (1.0_f32 / l) # Multiplying by inverse is often faster than two divisions
  end

  def self.distance(dx : GSDL::Num, dy : GSDL::Num) : Float32
    Math.hypot(dx.to_f32, dy.to_f32)
  end
end
