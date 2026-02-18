require "./shape"

module GSDL
  class Pie < Circle
    alias Vertices = Array(Vertex)
    alias Indices = Array(Int32)

    DefaultStartAngle = 0_f32
    DefaultEndAngle = (Math::PI * 1.75).to_f32 # circle with an eighth missing
    DefaultSegments = 64_u8

    properties_changed({
      start_angle: Num = DefaultStartAngle,
      end_angle: Num = DefaultEndAngle
    })

    def initialize(@radius : Num = 16, @start_angle : Num = DefaultStartAngle, @end_angle : Num = DefaultEndAngle)
      super()
    end

    def initialize(
      x : Num = 0,
      y : Num = 0,
      radius : Num = 16,
      @start_angle : Num = DefaultStartAngle,
      @end_angle : Num = DefaultEndAngle,
      color : Color = Color::White,
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill,
      border_thickness : Num = 1,
      border_color : Color = Color::White
    )
      super(
        x: x,
        y: y,
        radius: radius,
        color: color,
        draw_mode: draw_mode,
        border_thickness: border_thickness,
        border_color: border_color
      )
    end

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32

      if radius > 0
        # TODO: calculate this, like resolution in Oval
        segments = DefaultSegments
        angle_step = (end_angle - start_angle) / segments

        # Center vertex
        @fill_vertices << Vertex.new(center_x.to_f32, center_y.to_f32, color.to_fcolor)

        # Vertices along the arc
        (segments + 1).times do |i|
          angle = start_angle + i * angle_step
          arc_x = center_x + radius / 2 * Math.cos(angle)
          arc_y = center_y + radius / 2 * Math.sin(angle)
          @fill_vertices << Vertex.new(arc_x.to_f32, arc_y.to_f32, color.to_fcolor)
        end

        # Indices for triangle fan from the center
        # Center vertex is index 0
        # Arc vertices start from index 1
        segments.times do |i|
          @fill_indices << 0 # Center
          @fill_indices << i + 1 # Current arc point
          @fill_indices << i + 2 # Next arc point
        end
      end

      @changed = false
    end

    private def draw_filled(draw : Draw)
      update_geometry if changed?
      draw.geometry(@fill_vertices, @fill_indices)
    end

    private def draw_outline(draw : Draw)
      # TODO: Implement draw_outline for Pie
    end

    private def draw_border(draw : Draw)
      # TODO: Implement draw_border for Pie
    end
  end
end
