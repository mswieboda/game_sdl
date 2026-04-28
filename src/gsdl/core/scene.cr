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

    @entities = [] of Entity
    getter entities

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

    def add_child(entity : Entity)
      entity.parent = self
      @entities << entity
      entity
    end

    def save_snapshot : Hash(String, JSON::Any)
      entities_state = {} of String => JSON::Any
      @entities.each_with_index do |entity, i|
        # Use object ID or a custom name if available as key
        key = "entity_#{i}"
        entities_state[key] = JSON.parse(entity.save_state.to_json)
      end
      {
        "room_id" => JSON::Any.new(name.to_s),
        "entities" => JSON::Any.new(entities_state)
      }
    end

    def remove_child(entity : Entity)
      @entities.delete(entity)
      entity.parent = nil
      entity
    end

    def self.loading_scene_class(target_scene_class : T.class, data : SwitchData? = nil) : LoadingSceneBase forall T
      LoadingScene(T).new(target_scene_class, data)
    end

    def init
    end

    def exit
      @exit = true
    end

    def exit_with_transition
      @transition_out.start
    end

    def reset
      @exit = false
    end

    def update(dt : Float32)
      if self.is_a?(SceneCollisions)
        self.refresh_collision_space
      end
      @hud.try &.update(dt)
      @entities.each &.update(dt)
    end

    def draw(draw : Draw)
      @entities.each &.draw(draw)
      @hud.try &.draw(draw)
    end
  end

  abstract class LoadingSceneBase < Scene
    abstract def next_scene_class : Scene.class
  end
end
