module GSDL
  module MoveController
    # requires
    abstract def x : Num
    abstract def y : Num
    abstract def x=(x : Num)
    abstract def y=(y : Num)
    abstract def move_speed : Num
    abstract def draw_x : Num
    abstract def draw_y : Num
    abstract def draw_width : Num
    abstract def draw_height : Num
    abstract def collision_bounding_box : FRect

    property dx : Num = 0
    property dy : Num = 0

    def move_input
      self.dx = 0
      self.dy = 0

      self.dx -= 1 if Input.action?(:move_left)
      self.dx += 1 if Input.action?(:move_right)
      self.dy -= 1 if Input.action?(:move_up)
      self.dy += 1 if Input.action?(:move_down)
    end

    def move(dt : Float32)
      speed = move_speed * dt

      self.x += self.dx * speed
      self.y += self.dy * speed
    end

    def move_and_collide?(dt : Float32, collidables : Array(Collidable), tile_map : TileMap? = nil)
      speed = move_speed * dt

      # Move X
      previous_x = self.x
      self.x += dx * speed
      if collides_with_anything?(collidables, tile_map)
        self.x = previous_x
        return true
      end

      # Move Y
      previous_y = self.y
      self.y += dy * speed
      if collides_with_anything?(collidables, tile_map)
        self.y = previous_y
        return true
      end

      false
    end

    def move_and_collide(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?)
      move_and_collide?(dt, collidables, tile_map)
    end

    private def collides_with_anything?(collidables : Array(Collidable), tile_map : TileMap?) : Bool
      return true if collidables.any? { |c| collides?(c) }

      if tm = tile_map
        return true if tm.solid_up?(draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
        return true if tm.solid_down?(draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
        return true if tm.solid_left?(draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
        return true if tm.solid_right?(draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
      end

      false
    end
  end
end
