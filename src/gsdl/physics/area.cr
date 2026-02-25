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
      area_box.in?(x: x, y: y)
    end

    # TODO: maybe rename to overlaps? for consistency
    def in?(other : Area) : Bool
      other.area_box.overlaps?(area_box)
    end

    # TODO: maybe rename to overlaps? for consistency
    def in?(other : Collidable) : Bool
      other.collision_box.overlaps?(area_box)
    end
  end
end
