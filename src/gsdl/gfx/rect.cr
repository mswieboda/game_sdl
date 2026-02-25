module GSDL
  alias Rects = Array(Rect)
  alias IntType = UInt8 | UInt16 | UInt32 | Int8 | Int16 | Int32 | Int64

  struct Rect
    @internal : SDL3::Rect

    delegate x, :"x=", to: @internal
    delegate y, :"y=", to: @internal
    delegate w, :"w=", to: @internal
    delegate h, :"h=", to: @internal
    delegate width, :"width=", to: @internal
    delegate height, :"height=", to: @internal

    def initialize(frect : Rect)
      @internal = frect
    end

    # *h* (height) is optional, and defaults to *w* internally to make a square
    def initialize(x : Int = 0, y : Int = 0, w : Int = 0, h : Int? = nil)
      height = w

      if height_param = h
        height = height_param
      end

      @internal = SDL3::Rect.new(x: x.to_i, y: y.to_i, w: w.to_i, h: height.to_i)
    end

    def initialize(rect : Tuple(IntType, IntType, IntType, IntType))
      x, y, w, h = rect

      @internal = SDL3::Rect.new(x: x.to_i, y: y.to_i, w: w.to_i, h: h.to_i)
    end

    def initialize(point : Tuple(IntType, IntType), size : Tuple(IntType, IntType))
      x, y = point
      w, h = size

      @internal = SDL3::Rect.new(x: x.to_i, y: y.to_i, w: w.to_i, h: h.to_i)
    end

    # *h* (height) is optional, and defaults to *w* internally to make a square
    def initialize(point : Point, w : Int = 0, h : Int? = nil)
      height = w

      if height_param = h
        height = height_param
      end

      @internal = SDL3::Rect.new(x: point.x.to_i, y: point.y.to_i, w: w.to_i, h: height.to_i)
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

    def to_frect
      FRect.new(x: x.to_f32, y: y.to_f32, w: w.to_f32, h: h.to_f32)
    end

    def to_sdl
      @internal
    end

    def to_unsafe
      pointerof(@internal)
    end

    def self.overlaps?(rect_a : Rect, rect_b : Rect) : Bool
      return false if rect_a.right  <= rect_b.left
      return false if rect_a.left   >= rect_b.right
      return false if rect_a.bottom <= rect_b.top
      return false if rect_a.top    >= rect_b.bottom

      # If no gaps were found, the boxes must be overlapping
      true
    end

    def overlaps?(rect : Rect) : Bool
      Rect.overlaps?(self, rect)
    end

    def in?(x : Num, y : Num)
      x >= self.x && x <= self.right &&
        y >= self.y && y <= self.bottom
    end
  end
end
