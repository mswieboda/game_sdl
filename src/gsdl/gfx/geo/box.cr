require "./shape"

module GSDL
  alias FRect = SDL3::FRect
  alias Rect = SDL3::Rect

  class Box < Shape
    alias Vertices = Array(Vertex)
    alias Indices = Array(Int32)
    alias ArcPoints = Array(Array(FPoint))
    alias Num = Int32 | Float32

    GSDL::Shape.properties_changed({
      width: Num = 0,
      height: Num = 0,
      border_radius: UInt32 = 0
    })

    getters_update_geometry({
      fill_vertices: Vertices = [] of Vertex,
      fill_indices: Indices = [] of Int32,
      outline_arc_points: ArcPoints = [] of Array(FPoint)
    })

    def initialize(x, y, @width, @height, color : Color, @border_radius : UInt32 = 0)
      super(x: x, y: y, color: color)
    end

    def update_geometry
      @fill_vertices = [] of Vertex
      @fill_indices = [] of Int32
      @outline_arc_points = [] of Array(FPoint)

      if @border_radius > 0
        max_border_radius = ([width, height].min / 2).to_u32
        @border_radius = [border_radius, max_border_radius].min

        # top left, top right, bottom left, bottom right
        [
          { center: {x + border_radius, y + border_radius}, dir: {1_i8, 1_i8} },
          { center: {x + width - border_radius, y + border_radius}, dir: {-1_i8, 1_i8} },
          { center: {x + border_radius, y + height - border_radius}, dir: {1_i8, -1_i8} },
          { center: {x + width - border_radius, y + height - @border_radius}, dir: {-1_i8, -1_i8} }
        ].each do |data|
          build_corner_radius(center: data[:center], dir: data[:dir])
        end
      end

      @changed = false
    end

    private def build_corner_radius(center, dir : Tuple(Int8, Int8))
      center_x, center_y = center
      x_dir, y_dir = dir
      resolution = [12, (Math.sqrt(border_radius) * 2).to_i].max

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
      Rect.new(x: x.to_i, y: y.to_i, w: w.to_i, h: h.to_i)
    end

    def to_frect
      FRect.new(x: x.to_f32, y: y.to_f32, w: w.to_f32, h: h.to_f32)
    end

    def draw_filled(draw : Draw)
      if border_radius <= 0
        draw.color = color
        draw.filled(self)
      else
        update_geometry if changed?
        draw_filled_cross(draw)
        draw_filled_border_radius(draw)
      end
    end

    def draw_filled_cross(draw : Draw)
      draw.color = color
      draw.filled([
        Rect.new(
          x: x + border_radius,
          y: y,
          w: width - border_radius * 2,
          h: height,
        ),
        Rect.new(
          x: x,
          y: y + border_radius,
          w: width,
          h: height - border_radius * 2,
        )
      ])
    end

    def draw_filled_border_radius(draw : Draw)
      draw.geometry(@fill_vertices, @fill_indices)
    end

    def self.draw_filled(draw : Draw, rects : Array(Box))
      draw.color = rects.first.color
      draw.filled(rects)
    end

    def draw(draw : Draw)
      draw_filled(draw)
    end

    def draw_outline(draw : Draw)
      if border_radius <= 0
        draw.color = color
        draw.outline(self)
      else
        update_geometry if changed?
        draw_outline_cross(draw)
        draw_outline_border_radius(draw)
      end
    end

    def draw_outline_cross(draw : Draw)
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

    def draw_outline_border_radius(draw : Draw)
      draw.color = color

      @outline_arc_points.each do |points|
        draw.lines(points)
      end
    end

    def self.draw_outlines(draw : Draw, rects : Array(Box))
      draw.color = rects.first.color
      draw.outlines(rects)
    end

    def self.draw_outline(draw : Draw, rects : Array(Box))
      draw_outlines(draw, rects)
    end
  end
end
