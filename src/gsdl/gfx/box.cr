require "./drawable"

module GSDL
  alias FRect = SDL3::FRect
  alias Rect = SDL3::Rect

  class Box < Drawable
    alias Num = Int32 | Float32

    property width : Num
    property height : Num
    getter border_radius : UInt32

    @vertices : Array(Vertex)
    @indices : Array(Int32)

    def initialize(x, y, @width, @height, color : Color, @border_radius : UInt32 = 0, resolution : UInt8 = 16_u8)
      super(x: x, y: y, color: color)

      @vertices = [] of Vertex
      @indices = [] of Int32

      if @border_radius > 0
        max_border_radius = ([@width, @height].min / 2).to_u32
        @border_radius = [@border_radius, max_border_radius].min

        # top left
        build_corner_radius(
          center_x: @x + @border_radius,
          center_y: @y + @border_radius,
          x_dir: 1,
          y_dir: 1,
          resolution: resolution
        )

        # top right
        build_corner_radius(
          center_x: @x + @width - @border_radius,
          center_y: @y + @border_radius,
          x_dir: -1,
          y_dir: 1,
          resolution: resolution
        )

        # bottom left
        build_corner_radius(
          center_x: @x + @border_radius,
          center_y: @y + height - @border_radius,
          x_dir: 1,
          y_dir: -1,
          resolution: resolution
        )

        # bottom right
        build_corner_radius(
          center_x: @x + @width - @border_radius,
          center_y: @y + @height - @border_radius,
          x_dir: -1,
          y_dir: -1,
          resolution: resolution
        )
      end
    end

    private def build_corner_radius(center_x, center_y, x_dir : Int8, y_dir : Int8, resolution : UInt8)
      # Center vertex
      @vertices << Vertex.new(center_x.to_f32, center_y.to_f32, color.to_fcolor)

      start_v = @vertices.size

      # Arc vertices
      (resolution + 1).times do |i|
        angle = Math::PI + i * (0.5 * Math::PI / resolution)
        x = center_x + x_dir * border_radius * Math.cos(angle)
        y = center_y + y_dir * border_radius * Math.sin(angle)
        @vertices << Vertex.new(x.to_f32, y.to_f32, color.to_fcolor)
      end

      # Indices for triangle fan
      resolution.times do |i|
        @indices << start_v - 1
        @indices << start_v + i
        @indices << start_v + i + 1
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

    def draw(draw : Draw)
      draw_filled(draw)
    end

    def draw_filled(draw : Draw)
      if border_radius <= 0
        draw.color = color
        draw.filled(self)
      else
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
      draw.geometry(@vertices, @indices)
    end

    def self.draw_filled(draw : Draw, rects : Array(Box))
      draw.color = rects.first.color
      draw.filled(rects)
    end

    def draw_outline(draw : Draw)
      draw.color = color
      draw.outline(self)
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
