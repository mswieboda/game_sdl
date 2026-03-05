module GSDL
  module Area
    # requires
    abstract def draw_x : Num
    abstract def draw_y : Num

    # area bounding box for the trigger area
    abstract def area_bounding_box : FRect

    def area_box : FRect
      FRect.new(
        x: draw_x + area_bounding_box.x,
        y: draw_y + area_bounding_box.y,
        w: area_bounding_box.w,
        h: area_bounding_box.h
      )
    end

    # TODO: maybe rename to target_overlaps? for consistency
    def target_in?(x : Num, y : Num)
      area_box.overlaps?(x: x, y: y)
    end

    def overlaps?(other : Area) : Bool
      other.area_box.overlaps?(area_box)
    end

    def overlaps?(other : Collidable) : Bool
      other.collides?(area_box)
    end

    # Returns true if this object (if Directionable) is facing the other Area's draw coordinates.
    # Always returns true if this object is not Directionable.
    def facing_area?(other : Area) : Bool
      if self.is_a?(Directionable)
        self.facing?(other.draw_x, other.draw_y)
      else
        true
      end
    end

    # Checks if this Area intersects with another Area, is facing it, and (optionally) an input action is active.
    def area_triggered?(other : Area, action : Symbol | String | Nil = nil) : Bool
      if action && !Input.action?(action)
        return false
      end
      overlaps?(other) && facing_area?(other)
    end

    # Iterates over given areas and yields the first one that triggers the interaction condition.
    def on_area_trigger(others : Array(Area), action : Symbol | String | Nil = nil, &block : Area ->)
      others.find do |other|
        if area_triggered?(other, action)
          block.call(other)
          true
        else
          false
        end
      end
    end

    # Iterates over an array of mixed objects, filters by the given type (which must include Area),
    # and yields the first one that triggers the interaction condition.
    def on_area_trigger(others : Array, type : U.class, action : Symbol | String | Nil = nil, &block : U ->) forall U
      others.find do |other|
        if other.is_a?(U) && other.is_a?(Area) && area_triggered?(other, action)
          block.call(other)
          true
        else
          false
        end
      end
    end
  end
end
