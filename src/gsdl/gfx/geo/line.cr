require "./shape"

module GSDL
  class Line < Shape
    include Centerable

    property x2 : Num = 0
    property y2 : Num = 0

    def initialize(x1 : Num = 0, y1 : Num = 0, @x2 : Num = 0, @y2 : Num = 0, color : Color = Color::White, z_index = 0)
      super(x: x1, y: y1, color: color, z_index: z_index)
    end

    def initialize(p1 : Tuple(Num, Num), p2 : Tuple(Num, Num), color : Color = Color::White, z_index = 0)
      super(x: p1[0], y: p1[1], color: color, z_index: z_index)
      @x2, @y2 = p2
    end

    def initialize(points : Tuple(Num, Num, Num, Num), color : Color = Color::White, z_index = 0)
      super(x: points[0], y: points[1], color: color, z_index: z_index)
      @x2 = points[2]
      @y2 = points[3]
    end

    def x1 : Num
      x
    end

    def x1=(x1 : Num)
      self.x = x1
    end

    def y1 : Num
      y
    end

    def y1=(y1 : Num)
      self.y = y1
    end

    def x=(x : Num)
      dx = x - @x
      @x = x
      @x2 += dx
    end

    def y=(y : Num)
      dy = y - @y
      @y = y
      @y2 += dy
    end

    def width : Num
      (x2 - x1).abs.to_f32
    end

    def height : Num
      (y2 - y1).abs.to_f32
    end

    def draw_x : Num
      x1 - ((x2 - x1) * scale_x * origin_x)
    end

    def draw_y : Num
      y1 - ((y2 - y1) * scale_y * origin_y)
    end

    def distance : Float32
      Point.distance(x2 - x1, y2 - y1)
    end

    def center(x : Num = 0, y : Num = 0, width : Num = 1, height : Num = 1)
      # Capture the current relative vector before x1/y1 are changed
      vx = x2 - x1
      vy = y2 - y1

      # Move x1/y1 (inherited as x/y) to the center and set origin to 0.5
      _center(x: x, width: width, height: height)

      # Adjust x2/y2 so they maintain the same relative distance from x1/y1
      @x2 = x1 + vx
      @y2 = y1 + vy
    end

    def update_geometry
      @changed = false
    end

    def draw(draw : Draw)
      # Rotation pivot is (x1, y1) which is Shape (x, y)
      # We calculate the vector to the second point, scale it, and rotate it.
      p1 = rotate_point(draw_x, draw_y)
      
      # Calculate scaled vector from pivot
      dx = (x2 - x1).to_f32 * scale_x.to_f32
      dy = (y2 - y1).to_f32 * scale_y.to_f32
      
      # Rotate the second point relative to draw position
      p2 = rotate_point(draw_x + dx, draw_y + dy)
      
      draw.line(p1[0], p1[1], p2[0], p2[1], color: color, z_index: z_index)
    end
  end
end
