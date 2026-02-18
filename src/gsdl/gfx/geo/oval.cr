require "./shape"

module GSDL
  class Oval < Shape
    alias Vertices = Array(Vertex)
    alias Indices = Array(Int32)
    alias ArcPoints = Array(Array(FPoint))

    properties_changed({
      radius_x: Num = 16,
      radius_y: Num = 16
    })

    getters_update_geometry({
      fill_vertices: Vertices = [] of Vertex,
      fill_indices: Indices = [] of Int32,
      outline_arc_points: ArcPoints = [] of Array(FPoint)
    })

    def initialize(@radius_x : Num = 16, @radius_y : Num = 16)
      super(border_thickness: 1, border_color: Color::White) # Pass default values
    end

    def initialize(
      x : Num = 0,
      y : Num = 0,
      @radius_x : Num = 16,
      @radius_y : Num = 16,
      color : Color = Color::White,
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill,
      border_thickness : Num = 1,
      border_color : Color = Color::White
    )
      super(
        x: x,
        y: y,
        color: color,
        draw_mode: draw_mode,
        border_thickness: border_thickness,
        border_color: border_color
      )
    end

    # TODO: add setter
    def diameter_x : Num
      radius_x * 2
    end

    # TODO: add setter
    def diameter_y : Num
      radius_y * 2
    end

    # TODO: add setter
    def width : Num
      diameter_x
    end

    # TODO: add setter
    def height : Num
      diameter_y
    end

    # TODO: add setter
    def center_x : Num
      (x + radius_x / 2).to_f32
    end

    # TODO: add setter
    def center_y : Num
      (y + radius_y / 2).to_f32
    end

    def center(width : Num, height : Num)
      @x = ((width - self.radius_x) / 2).to_f32
      @y = ((height - self.radius_y) / 2).to_f32
    end

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32
      @outline_arc_points = [] of Array(FPoint)

      if radius_x > 0 && radius_y > 0
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
      corner_radius_x = radius_x / 2
      corner_radius_y = radius_y / 2
      max_radius = [corner_radius_x, corner_radius_y].max
      segments = [12, (Math.sqrt(max_radius) * 4).to_i].max

      # Center vertex
      @fill_vertices << Vertex.new(center_x.to_f32, center_y.to_f32, color.to_fcolor)

      start_v = @fill_vertices.size

      # Arc vertices
      points = [] of FPoint

      (segments + 1).times do |i|
        angle = Math::PI + i * (0.5 * Math::PI / segments)
        x = center_x + x_dir * corner_radius_x * Math.cos(angle)
        y = center_y + y_dir * corner_radius_y * Math.sin(angle)
        @fill_vertices << Vertex.new(x.to_f32, y.to_f32, color.to_fcolor)
        points << FPoint.new(x.to_f32, y.to_f32)
      end

      @outline_arc_points << points

      # Indices for triangle fan
      segments.times do |i|
        @fill_indices << start_v - 1
        @fill_indices << start_v + i
        @fill_indices << start_v + i + 1
      end
    end

    private def draw_filled(draw : Draw)
      update_geometry if changed?

      draw.geometry(@fill_vertices, @fill_indices)
    end

    private def draw_outline(draw : Draw)
      update_geometry if changed?

      draw.color = color

      @outline_arc_points.each do |points|
        draw.lines(points)
      end
    end

    private def draw_border(draw : Draw)
      border_thickness.to_i.times do |i|
        offset_x = self.x + i
        offset_y = self.y + i
        inner_radius_x = (self.radius_x - i * 2).to_f32
        inner_radius_y = (self.radius_y - i * 2).to_f32

        if inner_radius_x > 0 && inner_radius_y > 0
          Oval.new(
            x: offset_x,
            y: offset_y,
            radius_x: inner_radius_x,
            radius_y: inner_radius_y,
            color: self.border_color,
            draw_mode: Shape::DrawMode::Outline
          ).draw(draw)
        end
      end
    end
  end
end
