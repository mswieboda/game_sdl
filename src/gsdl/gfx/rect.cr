module GSDL
  class Rect < Drawable
    alias Num = Int32 | Float32

    property w : Num
    property h : Num

    def initialize(x, y, @w, @h, @color : Color? = nil)
      super(x: x, y: y, color: color)
    end

    def width : Num
      self.w
    end

    def height : Num
      self.height
    end

    def width=(width : Num)
      self.w=(width)
    end

    def height=(height : Num)
      self.h=(height)
    end

    def to_sdl
      SDL3::Rect.new(x: x.to_i, y: y.to_i, w: w.to_i, h: h.to_i)
    end

    def to_sdl_f32
      SDL3::FRect.new(x: x.to_f32, y: y.to_f32, w: w.to_f32, h: h.to_f32)
    end

    def draw(draw : Draw)
      draw_filled(draw)
    end

    def draw_filled(draw : Draw)
      draw_color(draw)
      draw.filled(self)
    end

    def self.draw_filled(draw : Draw, rects : Array(Rect), color : Color? = nil)
      draw_color(draw, color)
      draw.filled(rects)
    end

    def draw_outline(draw : Draw)
      draw_color(draw)
      draw.outline(self)
    end

    def self.draw_outlines(draw : Draw, rects : Array(Rect), color : Color? = nil)
      draw_color(draw, color)
      draw.outlines(rects)
    end

    def self.draw_outline(draw : Draw, rects : Array(Rect), color : Color? = nil)
      draw_outlines(draw, rects, color)
    end
  end
end
