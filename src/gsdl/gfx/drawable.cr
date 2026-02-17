module GSDL
  abstract class Drawable
    alias Num = Int32 | Float32

    property x : Num
    property y : Num
    property color : Color

    def initialize(@x, @y, @color : Color)
    end

    def draw(draw : Draw)
    end
  end
end
