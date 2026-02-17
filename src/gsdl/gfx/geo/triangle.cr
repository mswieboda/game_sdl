require "./shape"

module GSDL
  class Triangle < Shape
    properties_changed({
      x1: Num = 0,
      y1: Num = 0,
      x2: Num = 0,
      y2: Num = 0,
      x3: Num = 0,
      y3: Num = 0
    })

    def initialize(
      x1 : Num = 0,
      y1 : Num = 0,
      @x2 : Num = 0,
      @y2 : Num = 0,
      @x3 : Num = 0,
      @y3 : Num = 0,
      color : Color = Color::White
    )
      super(x: x1, y: y1, color: color)
    end

    def initialize(
      p1 : Tuple(Num, Num),
      p2 : Tuple(Num, Num),
      p3 : Tuple(Num, Num),
      color : Color = Color::White
    )
      x1, y1 = p1

      super(x: x1, y: y1, color: color)

      @x2, @y2 = p2
      @x3, @y3 = p3
    end

    def x1 : Num
      x
    end

    def y1 : Num
      y
    end

    def x1=(x1 : Num)
      self.x = x1
    end

    def y1=(y1 : Num)
      self.y = y1
    end

    def vertices : Array(Vertex)
      vertices = [] of Vertex
      fcolor = color.to_fcolor

      vertices << Vertex.new(x1.to_f32, y1.to_f32, fcolor)
      vertices << Vertex.new(x2.to_f32, y2.to_f32, fcolor)
      vertices << Vertex.new(x3.to_f32, y3.to_f32, fcolor)
    end

    def indices : Array(Int32)
      [0, 1, 2]
    end

    def update_geometry
    end

    def draw(draw : Draw)
      draw.geometry(vertices, indices)
    end

    def self.draw(draw : Draw, triangles : Array(Triangle))
      triangles.each(&.draw(draw))
    end
  end
end
