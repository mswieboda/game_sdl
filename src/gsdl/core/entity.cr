module GSDL
  abstract class Entity
    include Tweenable
    include Saveable

    def save_state : Hash(String, JSON::Any)
      {
        "x" => JSON::Any.new(x.to_f64),
        "y" => JSON::Any.new(y.to_f64),
        "visible" => JSON::Any.new(visible?)
      }
    end

    def load_state(state : Hash(String, JSON::Any))
      self.x = state["x"].as_f.to_f32
      self.y = state["y"].as_f.to_f32
      self.visible = state["visible"].as_bool
    end

    property x : Num = 0
    property y : Num = 0
    property z_index : Int32 = 0
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    property? active : Bool = true
    property? visible : Bool = true

    getter children = [] of Entity
    property parent : Entity | Scene | Nil = nil

    getter tweens : Array(Tween) = [] of Tween

    @[AlwaysInline]
    def global_x : Num
      if (p = parent) && p.is_a?(Entity)
        p.global_x + x
      else
        x
      end
    end

    @[AlwaysInline]
    def global_y : Num
      if (p = parent) && p.is_a?(Entity)
        p.global_y + y
      else
        y
      end
    end

    def root_scene : Scene?
      curr = parent
      while curr
        return curr if curr.is_a?(Scene)
        curr = curr.as?(Entity).try(&.parent)
      end
      nil
    end

    def add_child(entity : Entity)
      entity.parent = self
      @children << entity
      entity
    end

    def remove_child(entity : Entity)
      @children.delete(entity)
      entity.parent = nil
      entity
    end

    def update(dt : Float32) : Bool
      return false unless active?
      update_tweens(dt)
      @children.each &.update(dt)
      true
    end

    def draw(draw : Draw)
      return unless visible?
      @children.each &.draw(draw)
    end

    def origin_x : Float32
      origin[0]
    end

    def origin_y : Float32
      origin[1]
    end

    def scale_x : Num
      scale[0]
    end

    def scale_y : Num
      scale[1]
    end

    def scale_x=(scale_x : Num)
      @scale = {scale_x, scale_y}
    end

    def scale_y=(scale_y : Num)
      @scale = {scale_x, scale_y}
    end

    def scale=(scale : Num)
      @scale = {scale, scale}
    end
  end
end
