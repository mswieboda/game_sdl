require "./shape"

module GSDL
  alias Pixels = Array(Pixel)

  class Pixel < Shape
    def initialize(x : Num = 0, y : Num = 0, color : Color = Color::White, z_index : Int32 = 0)
      super(x: x, y: y, color: color, z_index: z_index)
    end

    def initialize(point : Tuple(Num, Num), color : Color = Color::White, z_index : Int32 = 0)
      super(x: point[0], y: point[1], color: color, z_index: z_index)
    end

    def width : Num
      1
    end

    def height : Num
      1
    end

    def to_point
      Point.new(x: x, y: y)
    end

    def update_geometry
      @changed = false
    end

    def draw(draw : Draw)
      # Rotation on a single pixel doesn't change its appearance,
      # but it will correctly pivot around its (x,y) if origin is used.
      draw.point(draw_x, draw_y, color: color, z_index: z_index)
    end
  end
end
