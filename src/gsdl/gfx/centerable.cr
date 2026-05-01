module GSDL
  module Centerable
    # requires
    abstract def x=(x : Num)
    abstract def y=(y : Num)
    abstract def origin_x : Float32
    abstract def origin_y : Float32
    abstract def render_width : Num
    abstract def render_height : Num

    def _center(x : Num = 0, y : Num = 0, width : Num = 1, height : Num = 1)
      self.x = x + width / 2_f32 + render_width * (origin_x - 0.5_f32)
      self.y = y + height / 2_f32 + render_height * (origin_y - 0.5_f32)
    end

    def center(x : Num = 0, y : Num = 0, width : Num = 1, height : Num = 1)
      _center(x: x, width: width, height: height)
    end

    def center_point_from_origin
      Point.new(
        x: origin_x * render_width,
        y: origin_y * render_height
      )
    end
  end
end
