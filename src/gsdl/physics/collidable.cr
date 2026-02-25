module GSDL
  module Collidable
    # requires
    abstract def draw_x : Num
    abstract def draw_y : Num

    # collision bounding box of the collidable object as an FRect
    abstract def collision_bounding_box : FRect

    def collision_box : FRect
      FRect.new(
        x: draw_x + collision_bounding_box.x,
        y: draw_y + collision_bounding_box.y,
        w: collision_bounding_box.w,
        h: collision_bounding_box.h
      )
    end

    def collides?(other : Collidable) : Bool
      collision_box.overlaps?(other.collision_box)
    end
  end
end
