module GSDL
  alias FPoint = SDL3::FPoint

  abstract class Point
    getter x : Num = 0
    getter y : Num = 0

    def initialize
    end

    def initialize(@x, @y)
    end

    abstract def draw(draw : Draw)

    def self.draw(draw : Draw, coords : Array(Coords))
      coords.each(&.draw(draw))
    end
  end
end
