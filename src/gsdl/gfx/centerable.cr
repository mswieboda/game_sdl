module GSDL
  module Centerable
    # requires
    abstract def x=(x : Num)
    abstract def y=(y : Num)
    abstract def origin=(origin : Tuple(Float32, Float32))

    def _center(x : Num = 0, y : Num = 0, width : Num = 1, height : Num = 1)
      self.x = x + width / 2_f32
      self.y = y + height / 2_f32
      self.origin = {0.5_f32, 0.5_f32}
    end

    def center(x : Num = 0, y : Num = 0, width : Num = 1, height : Num = 1)
      _center(x: x, width: width, height: height)
    end
  end
end
