module GSDL
  class Scene
    getter name
    getter? exit

    def initialize(name = :base)
      @name = name
      @exit = false
    end

    def init
    end

    def reset
      @exit = false
    end

    def update(dt : Float32)
    end

    def draw(draw : Draw)
    end
  end
end
