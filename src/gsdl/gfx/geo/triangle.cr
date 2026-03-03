require "./shape"

module GSDL
  class Triangle < Shape
    include Collidable

    properties_changed({
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
      origin : Tuple(Float32, Float32) = {0_f32, 0_f32},
      scale : Tuple(Num, Num) = {1_f32, 1_f32},
      rotation : Num = 0,
      color : Color = Color::White,
      z_index : Int32 = 0,
      draw_mode : GSDL::Shape::DrawMode = GSDL::Shape::DrawMode::Fill,
      border_thickness : Num = 1,
      border_color : Color = Color::White
    )
      super(
        x: x1,
        y: y1,
        origin: origin,
        scale: scale,
        rotation: rotation,
        color: color,
        z_index: z_index,
        draw_mode: draw_mode,
        border_thickness: border_thickness,
        border_color: border_color,
      )
    end

    def initialize(
      p1 : Tuple(Num, Num),
      p2 : Tuple(Num, Num),
      p3 : Tuple(Num, Num),
      origin : Tuple(Float32, Float32) = {0_f32, 0_f32},
      scale : Tuple(Num, Num) = {1_f32, 1_f32},
      rotation : Num = 0,
      color : Color = Color::White,
      z_index : Int32 = 0,
      draw_mode : GSDL::Shape::DrawMode = GSDL::Shape::DrawMode::Fill,
      border_thickness : Num = 1,
      border_color : Color = Color::White
    )
      x1, y1 = p1

      super(
        x: x1,
        y: y1,
        origin: origin,
        scale: scale,
        rotation: rotation,
        color: color,
        z_index: z_index,
        draw_mode: draw_mode,
        border_thickness: border_thickness,
        border_color: border_color,
      )

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

    def x=(x : Num)
      dx = x - @x
      @x = x
      @x2 += dx
      @x3 += dx
      @changed = true
    end

    def y=(y : Num)
      dy = y - @y
      @y = y
      @y2 += dy
      @y3 += dy
      @changed = true
    end

    def width : Num
      [x1, x2, x3].max - [x1, x2, x3].min
    end

    def height : Num
      [y1, y2, y3].max - [y1, y2, y3].min
    end

    def draw_x1 : Num
      base_min_x = [x1, x2, x3].min
      draw_x + (x1 - base_min_x) * scale_x
    end

    def draw_y1 : Num
      base_min_y = [y1, y2, y3].min
      draw_y + (y1 - base_min_y) * scale_y
    end

    def draw_x2 : Num
      base_min_x = [x1, x2, x3].min
      draw_x + (x2 - base_min_x) * scale_x
    end

    def draw_y2 : Num
      base_min_y = [y1, y2, y3].min
      draw_y + (y2 - base_min_y) * scale_y
    end

    def draw_x3 : Num
      base_min_x = [x1, x2, x3].min
      draw_x + (x3 - base_min_x) * scale_x
    end

    def draw_y3 : Num
      base_min_y = [y1, y2, y3].min
      draw_y + (y3 - base_min_y) * scale_y
    end

    def center(x : Num = 0, y : Num = 0, width : Num = 1, height : Num = 1)
      # Capture relative vectors for P2 and P3 from P1 (x, y)
      v2x = x2 - x1
      v2y = y2 - y1
      v3x = x3 - x1
      v3y = y3 - y1

      # Move x1/y1 (inherited as x/y) to center
      _center(x: x, y: y, width: width, height: height)

      # Maintain the triangle's shape relative to the new pivot
      @x2 = x1 + v2x
      @y2 = y1 + v2y
      @x3 = x1 + v3x
      @y3 = y1 + v3y
    end

    def vertices : Vertices
      vertices = [] of Vertex

      # Rotate each corner point
      p1 = rotate_point(draw_x1, draw_y1)
      p2 = rotate_point(draw_x2, draw_y2)
      p3 = rotate_point(draw_x3, draw_y3)

      vertices << Vertex.new(p1, color)
      vertices << Vertex.new(p2, color)
      vertices << Vertex.new(p3, color)
    end

    def indices : Array(Int32)
      [0, 1, 2]
    end

    def collision_shape : GSDL::Collidable::Shape
      GSDL::Collidable::Shape::Polygon
    end

    def collision_polygon_vertices : Points
      vertices.map { |v| Point.from(v) }
    end

    def collision_bounding_box : FRect
      # Rough bounding box for Collidable requirements
      FRect.new(x: [x1, x2, x3].min - x, y: [y1, y2, y3].min - y, w: width, h: height)
    end

    def update_geometry
    end

    private def draw_fill(draw : Draw)
      draw.geometry(vertices: vertices, indices: indices, z_index: z_index)
    end

    private def draw_outline(draw : Draw)
      vs = vertices
      lines = vs.map { |v| Point.from(v) }
      lines << Point.from(vs.first)

      draw.lines(points: lines, color: color, z_index: z_index)
    end

    private def draw_border(draw : Draw)
      vs = vertices
      original_lines = vs.map { |v| Point.from(v) }
      original_lines << Point.from(vs.first)

      border_thickness.to_i.times do |i|
        current_lines = original_lines.map(&.dup) # Work on a copy of points for each iteration
        
        # NOTE: Simple inset for rotated triangle is complex
        # For now we reuse the min/max logic which works best for axis-aligned
        # but will be skewed for rotated.
        # A proper fix requires line insetting (padding).
        
        if rotation == 0
          min_x_point_i = _find_index_by_accessor(current_lines, :min, &.x)
          min_y_point_i = _find_index_by_accessor(current_lines, :min, &.y)
          max_x_point_i = _find_index_by_accessor(current_lines, :max, &.x)
          max_y_point_i = _find_index_by_accessor(current_lines, :max, &.y)

          min_x_point = current_lines[min_x_point_i]
          min_x_point.x += i
          current_lines[min_x_point_i] = min_x_point

          min_y_point = current_lines[min_y_point_i]
          min_y_point.y += i
          current_lines[min_y_point_i] = min_y_point

          max_x_point = current_lines[max_x_point_i]
          max_x_point.x -= i
          current_lines[max_x_point_i] = max_x_point

          max_y_point = current_lines[max_y_point_i]
          max_y_point.y -= i
          current_lines[max_y_point_i] = max_y_point

          current_lines[-1] = current_lines.first
        end

        draw.lines(points: current_lines, color: border_color, z_index: z_index)
      end
    end

    # Generic helper to find the index of the min/max value of a `Points` property
    private def _find_index_by_accessor(
      points : Points,
      direction : Symbol, # :min or :max
      &accessor : Point -> Num
    ) : Int32
      return 0 if points.empty? # Return first index if empty or handle error

      best_val = accessor.call(points.first)
      best_idx = 0

      points.each_with_index do |point, index|
        current_val = accessor.call(point)
        if direction == :min
          if current_val < best_val
            best_val = current_val
            best_idx = index
          end
        else # direction == :max
          if current_val > best_val
            best_val = current_val
            best_idx = index
          end
        end
      end
      best_idx
    end
  end
end
