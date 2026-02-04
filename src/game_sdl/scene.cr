module GameSDL
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

    def update(frame_time : Float32)
    end

    def draw(renderer : SDL::Renderer, window : SDL::Window)
    end
  end
end
