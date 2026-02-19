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
      GSDL::Collidable.overlaps?(collision_box, other.collision_box)
    end

    def self.overlaps?(rect_a : FRect, rect_b : FRect) : Bool
      # Check if the rectangles overlap on both axes
      rect_a.x < rect_b.x + rect_b.w &&
      rect_a.x + rect_a.w > rect_b.x &&
      rect_a.y < rect_b.y + rect_b.h &&
      rect_a.y + rect_a.h > rect_b.y
    end
  end
end
