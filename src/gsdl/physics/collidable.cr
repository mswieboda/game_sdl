module GSDL
  module Collidable
    # collision bounding box of the collidable object as an SDL3::FRect
    abstract def collision_box : SDL3::FRect

    def collides?(other : Collidable) : Bool
      GSDL::Collidable.intersects?(collision_box, other.collision_box)
    end

    def self.intersects?(rect_a : SDL3::FRect, rect_b : SDL3::FRect) : Bool
      # Check if the rectangles overlap on both axes
      rect_a.x < rect_b.x + rect_b.w &&
      rect_a.x + rect_a.w > rect_b.x &&
      rect_a.y < rect_b.y + rect_b.h &&
      rect_a.y + rect_a.h > rect_b.y
    end
  end
end
