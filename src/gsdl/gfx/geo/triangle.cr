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
      color : Color = Color::White,
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill
    )
      super(x: x1, y: y1, color: color, draw_mode: draw_mode)
    end

    def initialize(
      p1 : Tuple(Num, Num),
      p2 : Tuple(Num, Num),
      p3 : Tuple(Num, Num),
      color : Color = Color::White,
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill
    )
      x1, y1 = p1

      super(x: x1, y: y1, color: color, draw_mode: draw_mode)

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

    def width : Num
      [x1, x2, x3].max - [x1, x2, x3].min
    end

    def height : Num
      [y1, y2, y3].max - [y1, y2, y3].min
    end

    def center(width : Num, height : Num)
      half_width = self.height / 2
      half_height = self.height / 2

      dx = ((width - self.width) / 2).to_f32
      dy = ((height - self.height) / 2).to_f32

      @x += dx - half_width
      @y += dy - half_height
      @x2 += dx - half_width
      @y2 += dy - half_height
      @x3 += dx - half_width
      @y3 += dy - half_height
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

    private def draw_filled(draw : Draw)
      draw.geometry(vertices, indices)
    end

    private def draw_outline(draw : Draw)
      draw.color = color
      lines = vertices.map { |v| FPoint.new(x: v.position.x.to_f32, y: v.position.y.to_f32) }
      lines << FPoint.new(x: vertices.first.position.x.to_f32, y: vertices.first.position.y.to_f32)

      draw.lines(lines)
    end

    def self.draw(draw : Draw, triangles : Array(Triangle))
      triangles.each(&.draw(draw))
    end
  end
end
