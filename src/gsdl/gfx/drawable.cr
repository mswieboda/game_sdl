module GSDL
  abstract class Drawable
    alias Num = Int32 | Float32

    property x : Num
    property y : Num
    property color : Color?

    def initialize(@x, @y, @color : Color? = nil)
    end

    def draw_color(draw : Draw)
      if c = color
        draw.color = c
      end
    end

    def self.draw_color(draw : Draw, color : Color? = nil)
      if c = color
        draw.color = c
      end
    end

    def draw(draw : Draw)
    end
  end
end
