module GSDL
  class Scene
    getter name
    getter? exit

    property transition_in : Transition = EmptyTransition.new
    property transition_out : Transition = EmptyTransition.new

    def initialize(
      @name : Symbol = :base,
      @transition_in : Transition = EmptyTransition.new,
      @transition_out : Transition = EmptyTransition.new
    )
      @exit = false
    end

    def self.manifest : Array(Loader::AssetTask)
      [] of Loader::AssetTask
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
