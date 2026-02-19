require "./shape"

module GSDL
  class Pie < Circle
    alias Vertices = Array(Vertex)
    alias Indices = Array(Int32)

    DefaultStartAngle = 0_f32
    DefaultEndAngle = (Math::PI * 1.75).to_f32 # circle with an eighth missing

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
      @outline_arc_points = [] of Array(FPoint)

      if radius > 0
        # TODO: calculate this, like resolution in Oval
        segments = [12, (Math.sqrt(radius) * 4).to_i].max
        angle_step = (end_angle - start_angle) / segments

        points = [] of FPoint

        # Center vertex
        @fill_vertices << Vertex.new(center_x.to_f32, center_y.to_f32, color.to_fcolor)
        center_point = FPoint.new(center_x.to_f32, center_y.to_f32)
        points << center_point


        # Vertices along the arc
        (segments + 1).times do |i|
          angle = start_angle + i * angle_step
          arc_x = center_x + radius / 2 * Math.cos(angle)
          arc_y = center_y + radius / 2 * Math.sin(angle)
          @fill_vertices << Vertex.new(arc_x.to_f32, arc_y.to_f32, color.to_fcolor)
          points << FPoint.new(arc_x.to_f32, arc_y.to_f32)
        end

        points << center_point

        @outline_arc_points << points

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

      draw.geometry(z_index, @fill_vertices, @fill_indices)
    end

    private def draw_border(draw : Draw)
      offset_cx = self.outline_arc_points.first[0].x
      offset_cy = self.outline_arc_points.first[0].y

      first_arc_pos = self.outline_arc_points.first[1]
      last_arc_pos = self.outline_arc_points.first[-2]

      border_thickness.to_i.times do |i|
        offset_x = self.x + i
        offset_y = self.y + i
        inner_radius = (self.radius - i * 2).to_f32

        if inner_radius > 0
          Pie.new(
            x: offset_x,
            y: offset_y,
            radius: inner_radius,
            start_angle: self.start_angle,
            end_angle: self.end_angle,
            color: self.border_color,
            draw_mode: Shape::DrawMode::Outline
          ).draw(draw)
        end

        # draw lines for straight pie edge
        # NOTE: this one is better then the second line for some reason
        Line.new(
          x1: offset_cx + i * Math.sin(self.start_angle),
          y1: offset_cy + i * Math.cos(self.start_angle),
          x2: first_arc_pos.x + i * Math.sin(self.start_angle),
          y2: first_arc_pos.y + i * Math.cos(self.start_angle),
          color: self.border_color
        ).draw(draw)

        # TODO: this one is not working well for some reason
        Line.new(
          x1: offset_cx + i * Math.sin(self.end_angle),
          y1: offset_cy + i * Math.cos(self.end_angle),
          x2: last_arc_pos.x + i * Math.sin(self.end_angle),
          y2: last_arc_pos.y + i * Math.cos(self.end_angle),
          color: self.border_color
        ).draw(draw)
      end
    end
  end
end
