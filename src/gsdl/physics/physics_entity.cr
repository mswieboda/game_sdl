require "../core/entity"
require "./collidable"
require "./body"
require "./physics_controller"

module GSDL
  class PhysicsEntity < Entity
    include Collidable
    include Body
    include PhysicsController

    property collision_width : Float32 = 0_f32
    property collision_height : Float32 = 0_f32
    property collision_offset_x : Float32 = 0_f32
    property collision_offset_y : Float32 = 0_f32

    def draw_x : Num
      scene_x
    end

    def draw_y : Num
      scene_y
    end

    def collision_bounding_box : FRect
      FRect.new(
        x: collision_offset_x,
        y: collision_offset_y,
        w: collision_width,
        h: collision_height
      )
    end
  end
end
