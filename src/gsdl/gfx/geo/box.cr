require "./shape"

module GSDL
  class Box < Shape
    include Collidable
    alias Indices = Array(Int32)
    alias ArcPoints = Array(Points)

    properties_changed({
      width: Num = 0,
      height: Num = 0,
      border_radius: Num = 0
    })

    getters_update_geometry({
      fill_vertices: Vertices = [] of Vertex,
      fill_indices: Indices = [] of Int32,
      outline_arc_points: ArcPoints = [] of Points
    })

    def initialize(@width : Num = 1, @height : Num = 1, @border_radius : Num = 0)
      super()
    end

    def initialize(
      @width : Num = 1,
      @height : Num = 1,
      x : Num = 0,
      y : Num = 0,
      color : Color = Color::White,
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      rotation : Num = 0,
      z_index : Int32 = 0,
      draw_mode : GSDL::Shape::DrawMode = GSDL::Shape::DrawMode::Fill,
      border_thickness : Num = 1,
      border_color : Color = Color::White,
      @border_radius : Num = 0
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

    def render_border_radius : Num
      border_radius * [scale_x, scale_y].min
      max_border_radius = ([render_width, render_height].min / 2).to_f32
      [border_radius, max_border_radius].min
    end

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32
      @outline_arc_points = [] of Points

      # For rotated box with sharp corners, we need to generate vertices
      if rotation != 0 && render_border_radius <= 0
        # Define 4 corners relative to render_x, render_y
        p1 = rotate_point(render_x, render_y)
        p2 = rotate_point(render_x + render_width, render_y)
        p3 = rotate_point(render_x + render_width, render_y + render_height)
        p4 = rotate_point(render_x, render_y + render_height)

        @fill_vertices << Vertex.new(point: p1, color: color)
        @fill_vertices << Vertex.new(point: p2, color: color)
        @fill_vertices << Vertex.new(point: p3, color: color)
        @fill_vertices << Vertex.new(point: p4, color: color)

        @fill_indices = [0, 1, 2, 0, 2, 3]

        @outline_arc_points << [
          Point.new(p1),
          Point.new(p2),
          Point.new(p3),
          Point.new(p4),
          Point.new(p1)
        ]
      elsif render_border_radius > 0
        # top left, top right, bottom left, bottom right
        [
          { center: {render_x + render_border_radius, render_y + render_border_radius}, dir: {1_i8, 1_i8} },
          { center: {render_x + render_width - render_border_radius, render_y + render_border_radius}, dir: {-1_i8, 1_i8} },
          { center: {render_x + render_border_radius, render_y + render_height - render_border_radius}, dir: {1_i8, -1_i8} },
          { center: {render_x + render_width - render_border_radius, render_y + render_height - render_border_radius}, dir: {-1_i8, -1_i8} }
        ].each do |data|
          build_corner_radius(center: data[:center], dir: data[:dir], radius: render_border_radius)
        end
      end

      @changed = false
    end

    private def build_corner_radius(center, dir : Tuple(Int8, Int8), radius : Num)
      center_x, center_y = center
      x_dir, y_dir = dir
      segments = [12, (Math.sqrt(radius) * 4).to_i].max

      # Center vertex (rotated)
      cp = rotate_point(center_x, center_y)
      @fill_vertices << Vertex.new(cp, color)

      start_v = @fill_vertices.size

      # Arc vertices (rotated)
      points = [] of Point

      (segments + 1).times do |i|
        angle = Math::PI + i * (0.5 * Math::PI / segments)
        vx = center_x + x_dir * radius * Math.cos(angle)
        vy = center_y + y_dir * radius * Math.sin(angle)

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

    def w : Num
      self.width
    end

    def h : Num
      self.height
    end

    def w=(width : Num)
      self.width = width
    end

    def h=(height : Num)
      self.height = height
    end

    def left
      x
    end

    def right
      x + width
    end

    def top
      y
    end

    def bottom
      y + height
    end

    def collision_shape : GSDL::Collidable::Shape
      if rotation != 0
        GSDL::Collidable::Shape::Polygon
      else
        GSDL::Collidable::Shape::Rect
      end
    end

    def collision_polygon_vertices : Points
      [
        Point.new(rotate_point(render_x, render_y)),
        Point.new(rotate_point(render_x + render_width, render_y)),
        Point.new(rotate_point(render_x + render_width, render_y + render_height)),
        Point.new(rotate_point(render_x, render_y + render_height))
      ]
    end

    def collision_bounding_box : FRect
      if rotation == 0
        FRect.new(x: -render_width * origin_x, y: -render_height * origin_y, w: render_width, h: render_height)
      else
        # For rotated, return a box that contains all rotated vertices
        vs = collision_polygon_vertices
        min_x = vs.min_of(&.x)
        max_x = vs.max_of(&.x)
        min_y = vs.min_of(&.y)
        max_y = vs.max_of(&.y)
        FRect.new(x: min_x - x, y: min_y - y, w: max_x - min_x, h: max_y - min_y)
      end
    end

    def to_rect
      Rect.new(x: render_x.to_i, y: render_y.to_i, w: render_width.to_i, h: render_height.to_i)
    end

    def to_frect
      FRect.new(x: render_x, y: render_y, w: render_width, h: render_height)
    end

    private def draw_fill(draw : Draw)
      if rotation == 0 && render_border_radius <= 0
        draw.rect_fill(to_frect, color: color, z_index: z_index)
      else
        update_geometry if changed?

        if render_border_radius > 0
          draw_fill_cross(draw)
        end
        draw_fill_border_radius(draw)
      end
    end

    # Rotate the 4 corners of each cross-rect and draw as geometry
    private def draw_fill_cross(draw : Draw)
      r = render_border_radius.to_f32

      # 1. Center-vertical strip (spans full height, but not full width)
      # x ranges from [render_x + r, render_x + render_width - r]
      # y ranges from [render_y, render_y + render_height]
      hx = render_x.to_f32 + r
      hy = render_y.to_f32
      hw = render_width.to_f32 - r * 2
      hh = render_height.to_f32

      draw_rotated_rect(draw, hx, hy, hw, hh)

      # 2. Left side strip (spans partial height, from y + r to y + h - r)
      # x ranges from [render_x, render_x + r]
      # y ranges from [render_y + r, render_y + render_height - r]
      lx = render_x.to_f32
      ly = render_y.to_f32 + r
      lw = r
      lh = render_height.to_f32 - r * 2

      draw_rotated_rect(draw, lx, ly, lw, lh)

      # 3. Right side strip (spans partial height, from y + r to y + h - r)
      # x ranges from [render_x + render_width - r, render_x + render_width]
      # y ranges from [render_y + r, render_y + render_height - r]
      rx = render_x.to_f32 + render_width.to_f32 - r
      ry = render_y.to_f32 + r
      rw = r
      rh = render_height.to_f32 - r * 2

      draw_rotated_rect(draw, rx, ry, rw, rh)
    end

    private def draw_rotated_rect(draw : Draw, rx, ry, rw, rh)
      return if rw <= 0 || rh <= 0

      p1 = rotate_point(rx, ry)
      p2 = rotate_point(rx + rw, ry)
      p3 = rotate_point(rx + rw, ry + rh)
      p4 = rotate_point(rx, ry + rh)

      draw.geometry(
        vertices: [
          Vertex.new(p1, color),
          Vertex.new(p2, color),
          Vertex.new(p3, color),
          Vertex.new(p4, color)
        ],
        indices: [0, 1, 2, 0, 2, 3],
        z_index: z_index
      )
    end

    private def draw_fill_border_radius(draw : Draw)
      draw.geometry(vertices: @fill_vertices, indices: @fill_indices, z_index: z_index)
    end

    private def draw_outline(draw : Draw)
      if rotation == 0 && render_border_radius <= 0
        draw.rect_outline(to_frect, color: color, z_index: z_index)
      else
        update_geometry if changed?
        if render_border_radius > 0
          draw_outline_cross(draw)
        end
        draw_outline_border_radius(draw)
      end
    end

    private def draw_outline_cross(draw : Draw)
      # top
      p1 = rotate_point(render_x + render_border_radius, render_y)
      p2 = rotate_point(render_x + render_width - render_border_radius, render_y)
      draw.line(p1[0], p1[1], p2[0], p2[1], color: color, z_index: z_index)

      # bottom
      p3 = rotate_point(render_x + render_border_radius, render_y + render_height)
      p4 = rotate_point(render_x + render_width - render_border_radius, render_y + render_height)
      draw.line(p3[0], p3[1], p4[0], p4[1], color: color, z_index: z_index)

      # left
      p5 = rotate_point(render_x, render_y + render_border_radius)
      p6 = rotate_point(render_x, render_y + render_height - render_border_radius)
      draw.line(p5[0], p5[1], p6[0], p6[1], color: color, z_index: z_index)

      # right
      p7 = rotate_point(render_x + render_width, render_y + render_border_radius)
      p8 = rotate_point(render_x + render_width, render_y + render_height - render_border_radius)
      draw.line(p7[0], p7[1], p8[0], p8[1], color: color, z_index: z_index)
    end

    private def draw_outline_border_radius(draw : Draw)
      @outline_arc_points.each do |points|
        draw.lines(points: points, color: color, z_index: z_index)
      end
    end

    private def draw_border(draw : Draw)
      return if border_thickness <= 0

      border_thickness.to_i.times do |i|
        off = i.to_f32

        # Calculate concentric dimensions and position
        new_width = width - (off * 2)
        new_height = height - (off * 2)

        next if new_width <= 0 || new_height <= 0

        # Shift the position to keep the box centered regardless of the origin
        new_x = x.to_f32 + off * (1.0_f32 - 2.0_f32 * origin_x)
        new_y = y.to_f32 + off * (1.0_f32 - 2.0_f32 * origin_y)

        # Radius must shrink as we move inward to stay concentric
        new_radius = Math.max(0_f32, border_radius.to_f32 - off)

        if rotation == 0 && new_radius <= 0
          # Fast path for simple rects
          draw.rect_outline(
            rect: FRect.new(
              x: new_x - new_width * origin_x,
              y: new_y - new_height * origin_y,
              w: new_width,
              h: new_height
            ),
            color: border_color,
            z_index: z_index
          )
        else
          # Fallback for complex shapes (rotated or rounded)
          # Note: We use the border_color as the main color for the outline Box
          Box.new(
            width: new_width,
            height: new_height,
            origin: origin,
            x: new_x,
            y: new_y,
            rotation: rotation,
            color: border_color,
            z_index: z_index,
            draw_mode: GSDL::Shape::DrawMode::Outline,
            border_radius: new_radius
          ).draw(draw)
        end
      end
    end
  end
end
