module GSDL
  module Centerable
    # requires
    abstract def x=(x : Num)
    abstract def y=(y : Num)
    abstract def origin_x : Float32
    abstract def origin_y : Float32
    abstract def draw_width : Num
    abstract def draw_height : Num

    def _center(x : Num = 0, y : Num = 0, width : Num = 1, height : Num = 1)
      self.x = x + width / 2_f32 + draw_width * (origin_x - 0.5_f32)
      self.y = y + height / 2_f32 + draw_height * (origin_y - 0.5_f32)
    end

    def center(x : Num = 0, y : Num = 0, width : Num = 1, height : Num = 1)
      _center(x: x, width: width, height: height)
    end
  end
end
