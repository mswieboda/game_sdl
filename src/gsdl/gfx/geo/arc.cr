require "./oval"

module GSDL
  class Arc < Oval
    alias Vertices = Array(Vertex)
    alias Indices = Array(Int32)
    alias ArcPoints = Array(Array(FPoint))

    DefaultEndAngle = (Math::PI * 0.3).to_f32
    DefaultSegments = 64_u8

    properties_changed({
      start_angle: Num = 0,
      end_angle: Num = DefaultEndAngle,
      thickness: Num = 16
    })

    getters_update_geometry({
      fill_vertices: Vertices = [] of Vertex,
      fill_indices: Indices = [] of Int32,
      outline_arc_points: ArcPoints = [] of Array(FPoint)
    })

    def initialize(@start_angle : Num = 0, @end_angle : Num = DefaultEndAngle, @thickness : Num = 16)
      super()
    end

    def initialize(
      x,
      y,
      radius_x : Num = 16,
      radius_y : Num = 16,
      @start_angle : Num = 0,
      @end_angle : Num = DefaultEndAngle,
      @thickness : Num = 16,
      color : Color = Color::White,
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill
    )
      super(x: x, y: y, radius_x: radius_x, radius_y: radius_y, color: color, draw_mode: draw_mode)
    end

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32
      @outline_arc_points = [] of Array(FPoint)

      if radius_x > 0 && radius_y > 0
        # TODO: dynamically calc, like oval `resolution`
        segments = DefaultSegments
        angle_step = (end_angle - start_angle) / segments

        generate_vertices(segments)
        generate_indices(segments)
      end

      @changed = false
    end

    def generate_vertices(segments : UInt8)
      angle_step = (end_angle - start_angle) / segments
      fcolor = color.to_fcolor

      (segments + 1).times do |i|
        angle = start_angle + i * angle_step

        # Calculate points on inner and outer edges of the arc
        inner_radius_x = radius_x
        inner_radius_y = radius_y
        outer_radius_x = radius_x + thickness
        outer_radius_y = radius_y + thickness

        # Inner vertex
        inner_x = center_x + inner_radius_x * Math.cos(angle)
        inner_y = center_y + inner_radius_y * Math.sin(angle)
        @fill_vertices << Vertex.new(inner_x.to_f32, inner_y.to_f32, fcolor)

        # Outer vertex
        outer_x = center_x + outer_radius_x * Math.cos(angle)
        outer_y = center_y + outer_radius_y * Math.sin(angle)
        @fill_vertices << Vertex.new(outer_x.to_f32, outer_y.to_f32, fcolor)
      end
    end

    def generate_indices(segments : UInt8)
      segments.times do |i|
        v_inner_prev = i * 2
        v_outer_prev = i * 2 + 1
        v_inner_curr = i * 2 + 2
        v_outer_curr = i * 2 + 3

        # First triangle of the quad
        @fill_indices << v_inner_prev
        @fill_indices << v_outer_prev
        @fill_indices << v_inner_curr

        # Second triangle of the quad
        @fill_indices << v_outer_prev
        @fill_indices << v_inner_curr
        @fill_indices << v_outer_curr
      end
    end
  end
end
