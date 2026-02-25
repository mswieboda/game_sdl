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
      # Check if the rectangles overlap on both axes
      rect_a.x < rect_b.x + rect_b.w &&
      rect_a.x + rect_a.w > rect_b.x &&
      rect_a.y < rect_b.y + rect_b.h &&
      rect_a.y + rect_a.h > rect_b.y
    end

    def overlaps?(rect : Rect) : Bool
      Rect.overlaps?(self, rect)
    end

    def in?(x : Int, y : Int)
      x >= self.x && x <= self.x + self.w &&
        y >= self.y && y <= self.y + self.h
    end
  end
end
