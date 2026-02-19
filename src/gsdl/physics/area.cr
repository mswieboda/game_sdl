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

    def target_in?(x : Num, y : Num)
      box = area_box

      x >= box.x && x <= box.x + box.w &&
        y >= box.y && y <= box.y + box.h
    end

    def in?(other : Area) : Bool
      GSDL::Collidable.overlaps?(area_box, other.area_box)
    end

    def in?(other : Collidable) : Bool
      GSDL::Collidable.overlaps?(area_box, other.collision_box)
    end
  end
end
