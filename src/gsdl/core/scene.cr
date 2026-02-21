module GSDL
  class Scene
    getter name
    getter? exit

    property transition_in : Transition = EmptyTransition.new
    property transition_out : Transition = EmptyTransition.new

    def initialize(
      @name = :base,
      @transition_in = EmptyTransition.new,
      @transition_out = EmptyTransition.new
    )
      @exit = false
    end

    def init
    end

    def exit
      @exit = true
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
