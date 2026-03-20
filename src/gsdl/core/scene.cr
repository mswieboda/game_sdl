module GSDL
  alias SwitchDataValue = String | Int32 | Float32 | Bool | Symbol
  alias SwitchData = Hash(Symbol, SwitchDataValue)

  class Scene
    include Loadable

    getter name
    getter? exit

    property transition_in : Transition
    property transition_out : Transition
    property switch_data : SwitchData?
    property z_index : Int32 = 0
    property pause_scene : Scene?
    property hud : HUD?

    @camera : Camera?
    def camera : Camera
      @camera ||= Camera.new(width: Game.width, height: Game.height)
    end

    # Whether to draw scenes below this one
    property? transparent : Bool = false
    # Whether to update scenes below this one (e.g. for pause overlays)
    property? update_underlying : Bool = false

    def initialize(
      @name : Symbol = :base,
      transition_in : Transition? = nil,
      transition_out : Transition? = nil,
      @switch_data : SwitchData? = nil
    )
      @transition_in = transition_in || EmptyTransition.new
      @transition_out = transition_out || EmptyTransition.new
      @exit = false
    end

    def self.loading_scene_class(target_scene_class : T.class, data : SwitchData? = nil) : LoadingSceneBase forall T
      LoadingScene(T).new(target_scene_class, data)
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
      @hud.try &.update(dt)
    end

    def draw(draw : Draw)
      @hud.try &.draw(draw)
    end
  end

  abstract class LoadingSceneBase < Scene
    abstract def next_scene_class : Scene.class
  end
end
