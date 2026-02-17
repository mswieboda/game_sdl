require "./shape"

module GSDL
  class Circle < Shape
    alias Vertices = Array(Vertex)
    alias Indices = Array(Int32)
    alias ArcPoints = Array(Array(FPoint))

    properties_changed({
      radius: UInt32 = 16
    })

    getters_update_geometry({
      fill_vertices: Vertices = [] of Vertex,
      fill_indices: Indices = [] of Int32,
      outline_arc_points: ArcPoints = [] of Array(FPoint)
    })

    def initialize(@radius : UInt32 = 16)
      super()
    end

    def initialize(x, y, @radius : UInt32 = 16, color : Color = Color::White)
      super(x: x, y: y, color: color)
    end

    def diameter
      radius * 2
    end

    def width
      diameter
    end

    def height
      diameter
    end

    def center_x
      x + radius
    end

    def center_y
      y + radius
    end

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32
      @outline_arc_points = [] of Array(FPoint)

      if radius > 0
        # top left, top right, bottom left, bottom right
        [
          {1_i8, 1_i8},
          {-1_i8, 1_i8},
          {1_i8, -1_i8},
          {-1_i8, -1_i8}
        ].each do |dir|
          # TODO: maybe we can do 360 angles (dumbed down to depending on resolution)
          #   instead of doing 4 corners?
          build_corner(dir)
        end
      end

      @changed = false
    end

    private def build_corner(dir : Tuple(Int8, Int8))
      x_dir, y_dir = dir
      corner_radius = radius / 2
      resolution = [12, (Math.sqrt(corner_radius) * 4).to_i].max

      # Center vertex
      @fill_vertices << Vertex.new(center_x.to_f32, center_y.to_f32, color.to_fcolor)

      start_v = @fill_vertices.size

      # Arc vertices
      points = [] of FPoint

      (resolution + 1).times do |i|
        angle = Math::PI + i * (0.5 * Math::PI / resolution)
        x = center_x + x_dir * corner_radius * Math.cos(angle)
        y = center_y + y_dir * corner_radius * Math.sin(angle)
        @fill_vertices << Vertex.new(x.to_f32, y.to_f32, color.to_fcolor)
        points << FPoint.new(x.to_f32, y.to_f32)
      end

      @outline_arc_points << points

      # Indices for triangle fan
      resolution.times do |i|
        @fill_indices << start_v - 1
        @fill_indices << start_v + i
        @fill_indices << start_v + i + 1
      end
    end

    def draw(draw : Draw)
      draw_filled(draw)
    end

    def draw_filled(draw : Draw)
      update_geometry if changed?

      draw.geometry(@fill_vertices, @fill_indices)
    end

    def self.draw_filled(draw : Draw, circles : Array(Circle))
      draw.color = circles.first.color
      draw.filled(circles)
    end

    def draw_outline(draw : Draw)
      update_geometry if changed?

      draw.color = color

      @outline_arc_points.each do |points|
        draw.lines(points)
      end
    end

    def self.draw_outlines(draw : Draw, circles : Array(Circle))
      draw.color = circles.first.color
      draw.outlines(circles)
    end

    def self.draw_outline(draw : Draw, circles : Array(Circle))
      draw_outlines(draw, circles)
    end
  end
end
