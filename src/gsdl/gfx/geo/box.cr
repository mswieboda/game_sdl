require "./shape"

module GSDL
  alias FRect = SDL3::FRect
  alias Rect = SDL3::Rect

  class Box < Shape
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

    def initialize(@width : Num = 1, @height : Num = 1, @border_radius : Num = 0, rotation : Num = 0)
      super(rotation: rotation)
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
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill,
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

    def draw_border_radius : Num
      border_radius * [scale_x, scale_y].min
      max_border_radius = ([draw_width, draw_height].min / 2).to_f32
      [border_radius, max_border_radius].min
    end

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32
      @outline_arc_points = [] of Points

      # For rotated box with sharp corners, we need to generate vertices
      if rotation != 0 && draw_border_radius <= 0
        # Define 4 corners relative to draw_x, draw_y
        p1 = rotate_point(draw_x, draw_y)
        p2 = rotate_point(draw_x + draw_width, draw_y)
        p3 = rotate_point(draw_x + draw_width, draw_y + draw_height)
        p4 = rotate_point(draw_x, draw_y + draw_height)

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
      elsif draw_border_radius > 0
        # top left, top right, bottom left, bottom right
        [
          { center: {draw_x + draw_border_radius, draw_y + draw_border_radius}, dir: {1_i8, 1_i8} },
          { center: {draw_x + draw_width - draw_border_radius, draw_y + draw_border_radius}, dir: {-1_i8, 1_i8} },
          { center: {draw_x + draw_border_radius, draw_y + draw_height - draw_border_radius}, dir: {1_i8, -1_i8} },
          { center: {draw_x + draw_width - draw_border_radius, draw_y + draw_height - draw_border_radius}, dir: {-1_i8, -1_i8} }
        ].each do |data|
          build_corner_radius(center: data[:center], dir: data[:dir], radius: draw_border_radius)
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
      self.width=(width)
    end

    def h=(height : Num)
      self.height=(height)
    end

    def to_rect
      Rect.new(x: draw_x.to_i, y: draw_y.to_i, w: draw_width.to_i, h: draw_height.to_i)
    end

    def to_frect
      FRect.new(x: draw_x.to_f32, y: draw_y.to_f32, w: draw_width.to_f32, h: draw_height.to_f32)
    end

    private def draw_fill(draw : Draw)
      if rotation == 0 && draw_border_radius <= 0
        draw.rect_fill(to_frect, color: color, z_index: z_index)
      else
        update_geometry if changed?

        if draw_border_radius > 0
          draw_fill_cross(draw)
        end
        draw_fill_border_radius(draw)
      end
    end

    # Rotate the 4 corners of each cross-rect and draw as geometry
    private def draw_fill_cross(draw : Draw)
      # Horizontal rect
      hx = draw_x.to_f32 + draw_border_radius.to_f32
      hy = draw_y.to_f32
      hw = draw_width.to_f32 - draw_border_radius.to_f32 * 2
      hh = draw_height.to_f32
      
      hp1 = rotate_point(hx, hy)
      hp2 = rotate_point(hx + hw, hy)
      hp3 = rotate_point(hx + hw, hy + hh)
      hp4 = rotate_point(hx, hy + hh)
      
      draw.geometry(
        vertices: [
          Vertex.new(hp1, color),
          Vertex.new(hp2, color),
          Vertex.new(hp3, color),
          Vertex.new(hp4, color)
        ],
        indices: [0, 1, 2, 0, 2, 3],
        z_index: z_index
      )

      # Vertical rect
      vx = draw_x.to_f32
      vy = draw_y.to_f32 + draw_border_radius.to_f32
      vw = draw_width.to_f32
      vh = draw_height.to_f32 - draw_border_radius.to_f32 * 2

      vp1 = rotate_point(vx, vy)
      vp2 = rotate_point(vx + vw, vy)
      vp3 = rotate_point(vx + vw, vy + vh)
      vp4 = rotate_point(vx, vy + vh)

      draw.geometry(
        vertices: [
          Vertex.new(vp1, color),
          Vertex.new(vp2, color),
          Vertex.new(vp3, color),
          Vertex.new(vp4, color)
        ],
        indices: [0, 1, 2, 0, 2, 3],
        z_index: z_index
      )
    end

    private def draw_fill_border_radius(draw : Draw)
      draw.geometry(vertices: @fill_vertices, indices: @fill_indices, z_index: z_index)
    end

    private def draw_outline(draw : Draw)
      if rotation == 0 && draw_border_radius <= 0
        draw.rect_outline(to_frect, color: color, z_index: z_index)
      else
        update_geometry if changed?
        if draw_border_radius > 0
          draw_outline_cross(draw)
        end
        draw_outline_border_radius(draw)
      end
    end

    private def draw_outline_cross(draw : Draw)
      # top
      draw.line(
        x1: draw_x + draw_border_radius,
        y1: draw_y,
        x2: draw_x + draw_width - draw_border_radius,
        y2: draw_y,
        color: color,
        z_index: z_index
      )

      # bottom
      draw.line(
        x1: draw_x + draw_border_radius,
        y1: draw_y + draw_height,
        x2: draw_x + draw_width - draw_border_radius,
        y2: draw_y + draw_height,
        color: color,
        z_index: z_index
      )

      # left
      draw.line(
        x1: draw_x,
        y1: draw_y + draw_border_radius,
        x2: draw_x,
        y2: draw_y + draw_height - draw_border_radius,
        color: color,
        z_index: z_index
      )

      # right
      draw.line(
        x1: draw_x + draw_width,
        y1: draw_y + draw_border_radius,
        x2: draw_x + draw_width,
        y2: draw_y + draw_height - draw_border_radius,
        color: color,
        z_index: z_index
      )
    end

    private def draw_outline_border_radius(draw : Draw)
      @outline_arc_points.each do |points|
        draw.lines(points: points, color: color, z_index: z_index)
      end
    end

    private def draw_border(draw : Draw)
      return if border_thickness <= 0

      if draw_border_radius <= 0
        # Draw rotated border lines
        border_thickness.to_i.times do |i|
          # Offsets for nested lines if thickness > 1
          off = i.to_f32
          
          # 4 corners
          p1 = rotate_point(draw_x + off, draw_y + off)
          p2 = rotate_point(draw_x + draw_width - off, draw_y + off)
          p3 = rotate_point(draw_x + draw_width - off, draw_y + draw_height - off)
          p4 = rotate_point(draw_x + off, draw_y + draw_height - off)

          draw.line(p1[0], p1[1], p2[0], p2[1], color: border_color, z_index: z_index)
          draw.line(p2[0], p2[1], p3[0], p3[1], color: border_color, z_index: z_index)
          draw.line(p3[0], p3[1], p4[0], p4[1], color: border_color, z_index: z_index)
          draw.line(p4[0], p4[1], p1[0], p1[1], color: border_color, z_index: z_index)
        end
      else
        # use existing logic for rounded borders
        border_thickness.to_i.times do |i|
          inner_width = self.draw_width - (i * 2)
          inner_height = self.draw_height - (i * 2)

          if inner_width > 0 && inner_height > 0
            Box.new(
              width: inner_width,
              height: inner_height,
              origin: origin,
              x: self.x,
              y: self.y,
              rotation: self.rotation,
              color: self.border_color,
              z_index: z_index,
              draw_mode: Shape::DrawMode::Outline,
              border_radius: self.draw_border_radius
            ).draw(draw)
          end
        end
      end
    end
  end
end
