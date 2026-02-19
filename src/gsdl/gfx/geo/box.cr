require "./shape"

module GSDL
  alias FRect = SDL3::FRect
  alias Rect = SDL3::Rect

  class Box < Shape
    alias Vertices = Array(Vertex)
    alias Indices = Array(Int32)
    alias ArcPoints = Array(Array(FPoint))

    properties_changed({
      width: Num = 0,
      height: Num = 0,
      border_radius: Num = 0
    })

    getters_update_geometry({
      fill_vertices: Vertices = [] of Vertex,
      fill_indices: Indices = [] of Int32,
      outline_arc_points: ArcPoints = [] of Array(FPoint)
    })

    def initialize(@width, @height, @border_radius : Num = 0)
      super()
    end

    def initialize(
      @width,
      @height,
      x : Num = 0,
      y : Num = 0,
      color : Color = Color::White,
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill,
      border_thickness : Num = 1,
      border_color : Color = Color::White,
      @border_radius : Num = 0
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

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32
      @outline_arc_points = [] of Array(FPoint)

      if border_radius > 0
        max_border_radius = ([width, height].min / 2).to_f32
        @border_radius = [border_radius, max_border_radius].min

        # top left, top right, bottom left, bottom right
        [
          { center: {draw_x + border_radius, draw_y + border_radius}, dir: {1_i8, 1_i8} },
          { center: {draw_x + width - border_radius, draw_y + border_radius}, dir: {-1_i8, 1_i8} },
          { center: {draw_x + border_radius, draw_y + height - border_radius}, dir: {1_i8, -1_i8} },
          { center: {draw_x + width - border_radius, draw_y + height - @border_radius}, dir: {-1_i8, -1_i8} }
        ].each do |data|
          build_corner_radius(center: data[:center], dir: data[:dir])
        end
      end

      @changed = false
    end

    private def build_corner_radius(center, dir : Tuple(Int8, Int8))
      center_x, center_y = center
      x_dir, y_dir = dir
      resolution = [12, (Math.sqrt(border_radius) * 4).to_i].max

      # Center vertex
      @fill_vertices << Vertex.new(center_x.to_f32, center_y.to_f32, color.to_fcolor)

      start_v = @fill_vertices.size

      # Arc vertices
      points = [] of FPoint

      (resolution + 1).times do |i|
        angle = Math::PI + i * (0.5 * Math::PI / resolution)
        x = center_x + x_dir * border_radius * Math.cos(angle)
        y = center_y + y_dir * border_radius * Math.sin(angle)
        @fill_vertices << Vertex.new(x.to_f32, y.to_f32, color.to_fcolor)
        points << FPoint.new(x.to_f32, y.to_f32)
      end

      @outline_arc_points << points

      # Indices for triangle fan
      resolution.times do |i|
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
      Rect.new(x: draw_x.to_i, y: draw_y.to_i, w: w.to_i, h: h.to_i)
    end

    def to_frect
      FRect.new(x: draw_x.to_f32, y: draw_y.to_f32, w: w.to_f32, h: h.to_f32)
    end

    private def draw_filled(draw : Draw)
      if border_radius <= 0
        draw.color = color
        draw.filled(self)
      else
        update_geometry if changed?

        draw_filled_cross(draw)
        draw_filled_border_radius(draw)
      end
    end

    private def draw_filled_cross(draw : Draw)
      draw.color = color
      draw.filled([
        Rect.new(
          x: draw_x + border_radius,
          y: draw_y,
          w: width - border_radius * 2,
          h: height,
        ),
        Rect.new(
          x: draw_x,
          y: draw_y + border_radius,
          w: width,
          h: height - border_radius * 2,
        )
      ])
    end

    private def draw_filled_border_radius(draw : Draw)
      draw.geometry(z_index, @fill_vertices, @fill_indices)
    end

    private def draw_outline(draw : Draw)
      if border_radius <= 0
        draw.color = color
        draw.outline(self)
      else
        update_geometry if changed?
        draw_outline_cross(draw)
        draw_outline_border_radius(draw)
      end
    end

    private def draw_outline_cross(draw : Draw)
      draw.color = color

      # top
      draw.line(
        x1: x + border_radius,
        y1: y,
        x2: x + width - border_radius,
        y2: y,
      )

      # bottom
      draw.line(
        x1: x + border_radius,
        y1: y + height,
        x2: x + width - border_radius,
        y2: y + height,
      )

      # left
      draw.line(
        x1: x,
        y1: y + border_radius,
        x2: x,
        y2: y + height - border_radius,
      )

      # right
      draw.line(
        x1: x + width,
        y1: y + border_radius,
        x2: x + width,
        y2: y + height - border_radius,
      )
    end

    private def draw_outline_border_radius(draw : Draw)
      draw.color = color

      @outline_arc_points.each do |points|
        draw.lines(points)
      end
    end

    private def draw_border(draw : Draw)
      return if border_thickness <= 0

      draw.color = border_color

      if border_radius <= 0
        # draw four filled rectangles for a sharp-cornered border
        # top, bottom
        draw.filled(FRect.new(x: x, y: y, w: width, h: border_thickness))
        draw.filled(FRect.new(x: x, y: y + height - border_thickness, w: width, h: border_thickness))

        # left, right (adjust height to avoid overlapping corners)
        draw.filled(FRect.new(x: x, y: y + border_thickness, w: border_thickness, h: height - 2 * border_thickness))
        draw.filled(FRect.new(x: x + width - border_thickness, y: y + border_thickness, w: border_thickness, h: height - 2 * border_thickness))
      else
        # use existing logic for rounded borders
        border_thickness.to_i.times do |i|
          offset_x = self.x + i
          offset_y = self.y + i
          inner_width = self.width - (i * 2)
          inner_height = self.height - (i * 2)

          if inner_width > 0 && inner_height > 0
            Box.new(
              width: inner_width,
              height: inner_height,
              x: offset_x,
              y: offset_y,
              color: self.border_color,
              draw_mode: Shape::DrawMode::Outline,
              border_radius: self.border_radius
            ).draw(draw)
          end
        end
      end
    end
  end
end
