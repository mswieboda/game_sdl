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

    def initialize(@start_angle : Num = DefaultStartAngle, @end_angle : Num = DefaultEndAngle, rotation : Num = 0)
      super()
      @rotation = rotation
    end

    def initialize(
      x : Num = 0,
      y : Num = 0,
      origin = {0_f32, 0_f32},
      radius : Num = 16,
      scale = {1_f32, 1_f32},
      rotation : Num = 0,
      @start_angle : Num = DefaultStartAngle,
      @end_angle : Num = DefaultEndAngle,
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
        radius: radius,
        scale: scale,
        rotation: rotation,
        color: color,
        z_index: z_index,
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
        segments = [12, (Math.sqrt(draw_radius_x) * 4).to_i].max
        angle_step = (end_angle - start_angle) / segments

        points = [] of FPoint

        # Center vertex (rotated)
        cp = rotate_point(center_x, center_y)
        @fill_vertices << Vertex.new(cp[0], cp[1], color.to_fcolor)
        center_point = FPoint.new(cp[0], cp[1])
        points << center_point


        # Vertices along the arc (rotated)
        (segments + 1).times do |i|
          angle = start_angle + i * angle_step
          arc_x = center_x + (draw_radius_x / 2) * Math.cos(angle)
          arc_y = center_y + (draw_radius_y / 2) * Math.sin(angle)
          
          rv = rotate_point(arc_x, arc_y)
          @fill_vertices << Vertex.new(rv[0], rv[1], color.to_fcolor)
          points << FPoint.new(rv[0], rv[1])
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

    private def draw_border(draw : Draw)
      # We need to use rotated coordinates for the lines
      offset_cx = self.outline_arc_points.first[0].x
      offset_cy = self.outline_arc_points.first[0].y

      first_arc_pos = self.outline_arc_points.first[1]
      last_arc_pos = self.outline_arc_points.first[-2]

      border_thickness.to_i.times do |i|
        # Scale inner radius based on current scale
        inner_radius = (self.radius - i * 2).to_f32

        if inner_radius > 0
          Pie.new(
            x: self.x,
            y: self.y,
            origin: origin,
            radius: inner_radius,
            scale: scale,
            rotation: rotation,
            start_angle: self.start_angle,
            end_angle: self.end_angle,
            color: self.border_color,
            z_index: z_index,
            draw_mode: Shape::DrawMode::Outline
          ).draw(draw)
        end

        # Draw lines connecting center to arc ends
        # These are already rotated because the points come from @outline_arc_points
        draw.line(
          x1: offset_cx,
          y1: offset_cy,
          x2: first_arc_pos.x,
          y2: first_arc_pos.y,
          color: self.border_color,
          z_index: z_index
        )

        draw.line(
          x1: offset_cx,
          y1: offset_cy,
          x2: last_arc_pos.x,
          y2: last_arc_pos.y,
          color: self.border_color,
          z_index: z_index
        )
      end
    end
  end
end
