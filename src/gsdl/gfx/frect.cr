module GSDL
  alias FRects = Array(FRect)

  struct FRect
    @internal : SDL3::FRect

    delegate x, :"x=", to: @internal
    delegate y, :"y=", to: @internal
    delegate w, :"w=", to: @internal
    delegate h, :"h=", to: @internal
    delegate width, :"width=", to: @internal
    delegate height, :"height=", to: @internal

    def initialize(frect : FRect)
      @internal = frect
    end

    # *h* (height) is optional, and defaults to *w* internally to make a square
    def initialize(x : Num = 0, y : Num = 0, w : Num = 0, h : Num? = nil)
      height = w

      if height_param = h
        height = height_param
      end

      @internal = SDL3::FRect.new(x: x.to_f32, y: y.to_f32, w: w.to_f32, h: height.to_f32)
    end

    def initialize(rect : Tuple(Num, Num, Num, Num))
      x, y, w, h = rect

      @internal = SDL3::FRect.new(x: x.to_f32, y: y.to_f32, w: w.to_f32, h: h.to_f32)
    end

    def initialize(point : Tuple(Num, Num), size : Tuple(Num, Num))
      x, y = point
      w, h = size

      @internal = SDL3::FRect.new(x: x.to_f32, y: y.to_f32, w: w.to_f32, h: h.to_f32)
    end

    # *h* (height) is optional, and defaults to *w* internally to make a square
    def initialize(point : Point, w : Num = 0, h : Num? = nil)
      height = w

      if height_param = h
        height = height_param
      end

      @internal = SDL3::FRect.new(x: point.x.to_f32, y: point.y.to_f32, w: w.to_f32, h: height.to_f32)
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

    def to_rect
      Rect.new(x: x.to_i, y: y.to_i, w: w.to_i, h: h.to_i)
    end

    def to_sdl
      @internal
    end

    def to_unsafe
      pointerof(@internal)
    end

    def self.overlaps?(rect_a : FRect, rect_b : FRect) : Bool
      return false if rect_a.right  <= rect_b.left
      return false if rect_a.left   >= rect_b.right
      return false if rect_a.bottom <= rect_b.top
      return false if rect_a.top    >= rect_b.bottom

      # If no gaps were found, the boxes must be overlapping
      true
    end

    def overlaps?(rect : FRect) : Bool
      FRect.overlaps?(self, rect)
    end

    def in?(x : Num, y : Num)
      x >= self.x && x <= self.right &&
        y >= self.y && y <= self.bottom
    end
  end
end
