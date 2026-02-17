module GSDL
  class Rect < Drawable
    alias Num = Int32 | Float32

    property width : Num
    property height : Num

    def initialize(x, y, @width, @height, color : Color)
      super(x: x, y: y, color: color)
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
      draw.color = color
      draw.filled(self)
    end

    def self.draw_filled(draw : Draw, rects : Array(Rect))
      draw.color = rects.first.color
      draw.filled(rects)
    end

    def draw_outline(draw : Draw)
      draw.color = color
      draw.outline(self)
    end

    def self.draw_outlines(draw : Draw, rects : Array(Rect))
      draw.color = rects.first.color
      draw.outlines(rects)
    end

    def self.draw_outline(draw : Draw, rects : Array(Rect))
      draw_outlines(draw, rects)
    end
  end
end
