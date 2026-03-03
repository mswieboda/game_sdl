module GSDL
  alias Rects = Array(Rect)
  alias IntType = UInt8 | UInt16 | UInt32 | Int8 | Int16 | Int32 | Int64

  struct Rect
    @internal : SDL3::Rect

    def x : Int32
      @internal.x
    end

    def x=(value : Int32)
      @internal.x = value
    end

    def y : Int32
      @internal.y
    end

    def y=(value : Int32)
      @internal.y = value
    end

    def w : Int32
      @internal.w
    end

    def w=(value : Int32)
      @internal.w = value
    end

    def h : Int32
      @internal.h
    end

    def h=(value : Int32)
      @internal.h = value
    end

    def width : Int32
      @internal.width
    end

    def width=(value : Int32)
      @internal.width = value
    end

    def height : Int32
      @internal.height
    end

    def height=(value : Int32)
      @internal.height = value
    end

    def initialize(frect : Rect)
      @internal = frect
    end

    # *h* (height) is optional, and defaults to *w* internally to make a square
    def initialize(x : Int32 = 0, y : Int32 = 0, w : Int32 = 0, h : Int32? = nil)
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
    def initialize(point : Point, w : Int32 = 0, h : Int32? = nil)
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
