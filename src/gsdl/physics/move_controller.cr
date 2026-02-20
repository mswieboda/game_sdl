module GSDL
  module MoveController
    # requires
    abstract def x : Num
    abstract def y : Num
    abstract def x=(x : Num)
    abstract def y=(y : Num)
    abstract def move_speed : Num

    def move_left? : Bool
      Keys.pressed?([Keys::A, Keys::Left])
    end

    def move_right? : Bool
      Keys.pressed?([Keys::D, Keys::Right])
    end

    def move_up? : Bool
      Keys.pressed?([Keys::W, Keys::Up])
    end

    def move_down? : Bool
      Keys.pressed?([Keys::S, Keys::Down])
    end

    def move_and_collide?(dt : Float32, collidables : Array(Collidable)) : Bool
      previous_x = self.x
      previous_y = self.y

      move(dt)

      if collidables.any? { |c| collides?(c) }
        self.x = previous_x
        self.y = previous_y

        true
      else
        false
      end
    end

    def move(dt : Float32)
      speed = move_speed * dt

      self.x -= speed if move_left?
      self.x += speed if move_right?
      self.y -= speed if move_up?
      self.y += speed if move_down?
    end
  end
end
