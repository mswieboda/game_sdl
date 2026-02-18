require "./oval"

module GSDL
  class Arc < Oval
    alias Vertices = Array(Vertex)
    alias Indices = Array(Int32)
    alias ArcPoints = Array(FPoint)

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
      inner_arc_points: ArcPoints = [] of FPoint,
      outer_arc_points: ArcPoints = [] of FPoint
    })

    def initialize(@start_angle : Num = 0, @end_angle : Num = DefaultEndAngle, @thickness : Num = 16)
      super()
    end

    def initialize(
      x : Num = 0,
      y : Num = 0,
      radius_x : Num = 16,
      radius_y : Num = 16,
      color : Color = Color::White,
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill,
      @start_angle : Num = 0,
      @end_angle : Num = DefaultEndAngle,
      @thickness : Num = 16
    )
      super(x: x, y: y, radius_x: radius_x, radius_y: radius_y, color: color, draw_mode: draw_mode)
    end

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32
      @inner_arc_points = [] of FPoint
      @outer_arc_points = [] of FPoint

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
        @inner_arc_points << FPoint.new(inner_x.to_f32, inner_y.to_f32)

        # Outer vertex
        outer_x = center_x + outer_radius_x * Math.cos(angle)
        outer_y = center_y + outer_radius_y * Math.sin(angle)
        @fill_vertices << Vertex.new(outer_x.to_f32, outer_y.to_f32, fcolor)
        @outer_arc_points << FPoint.new(outer_x.to_f32, outer_y.to_f32)
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

    private def draw_outline(draw : Draw)
      update_geometry if changed?

      draw.color = color

      draw.lines(@inner_arc_points)
      draw.lines(@outer_arc_points)

      # draw connecting lines at start and end of the arc
      if inner_arc_points.size > 0 && outer_arc_points.size > 0
        # line at start of arc
        draw.line(inner_arc_points.first.x, inner_arc_points.first.y, outer_arc_points.first.x, outer_arc_points.first.y)
        # line at end of arc
        draw.line(inner_arc_points.last.x, inner_arc_points.last.y, outer_arc_points.last.x, outer_arc_points.last.y)
      end
    end
  end
end
