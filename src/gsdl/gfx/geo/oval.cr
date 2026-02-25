require "./shape"

module GSDL
  class Oval < Shape
    alias Indices = Array(Int32)
    alias ArcPoints = Array(Points)

    properties_changed({
      radius_x: Num = 16,
      radius_y: Num = 16
    })

    getters_update_geometry({
      fill_vertices: Vertices = [] of Vertex,
      fill_indices: Indices = [] of Int32,
      outline_arc_points: ArcPoints = [] of Points
    })

    def initialize(@radius_x : Num = 16, @radius_y : Num = 16, rotation : Num = 0)
      super(rotation: rotation, border_thickness: 1, border_color: Color::White) # Pass default values
    end

    def initialize(
      x : Num = 0,
      y : Num = 0,
      origin = {0_f32, 0_f32},
      @radius_x : Num = 16,
      @radius_y : Num = 16,
      scale = {1_f32, 1_f32},
      rotation : Num = 0,
      color : Color = Color::White,
      z_index : Int32 = 0,
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill,
      border_thickness : Num = 1,
      border_color : Color = Color::White
    )
      super(
        x: x,
        y: y,
        origin: origin,
        scale: scale,
        rotation: rotation,
        color: color,
        z_index: z_index,
        draw_mode: draw_mode,
        border_thickness: border_thickness,
        border_color: border_color
      )
    end

    def draw_radius_x : Num
      radius_x * scale_x
    end

    def draw_radius_y : Num
      radius_y * scale_y
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
      draw_x + draw_radius_x
    end

    # TODO: add setter
    def center_y : Num
      draw_y + draw_radius_y
    end

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32
      @outline_arc_points = [] of Points

      if draw_radius_x > 0 && draw_radius_y > 0
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

    # TODO: switch to start_angle to end_angle (360 deg)
    #   instead of doing this calc 4 times with each corner
    private def build_corner(dir : Tuple(Int8, Int8))
      x_dir, y_dir = dir
      corner_radius_x = draw_radius_x / 2
      corner_radius_y = draw_radius_y / 2
      max_radius = [corner_radius_x, corner_radius_y].max
      segments = [12, (Math.sqrt(max_radius) * 4).to_i].max

      # Center vertex (rotated)
      cp = rotate_point(center_x, center_y)
      @fill_vertices << Vertex.new(cp, color)

      start_v = @fill_vertices.size

      # Arc vertices (rotated)
      points = [] of Point

      (segments + 1).times do |i|
        angle = Math::PI + i * (0.5 * Math::PI / segments)
        vx = center_x + x_dir * corner_radius_x * Math.cos(angle)
        vy = center_y + y_dir * corner_radius_y * Math.sin(angle)
        
        rv = rotate_point(vx, vy)
        @fill_vertices << Vertex.new(rv, color)
        points << Point.new(rv)
      end

      @outline_arc_points << points

      # Indices for triangle fan
      segments.times do |i|
        @fill_indices << start_v - 1
        @fill_indices << start_v + i
        @fill_indices << start_v + i + 1
      end
    end

    private def draw_fill(draw : Draw)
      update_geometry if changed?

      draw.geometry(vertices: @fill_vertices, indices: @fill_indices, z_index: z_index)
    end

    private def draw_outline(draw : Draw)
      update_geometry if changed?

      @outline_arc_points.each do |points|
        draw.lines(points: points, color: color, z_index: z_index)
      end
    end

    private def draw_border(draw : Draw)
      border_thickness.to_i.times do |i|
        inner_radius_x = (self.draw_radius_x - i * 2).to_f32
        inner_radius_y = (self.draw_radius_y - i * 2).to_f32

        if inner_radius_x > 0 && inner_radius_y > 0
          Oval.new(
            x: self.x,
            y: self.y,
            origin: origin,
            radius_x: inner_radius_x / scale_x,
            radius_y: inner_radius_y / scale_y,
            scale: scale,
            rotation: rotation,
            color: self.border_color,
            z_index: z_index,
            draw_mode: Shape::DrawMode::Outline
          ).draw(draw)
        end
      end
    end
  end
end
