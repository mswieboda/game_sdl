module GSDL
  module VerticalScrollController
    include MoveController

    property auto_scroll_speed : Float32 = 0_f32
    property strafing_speed_x : Float32 = 256_f32
    property thrust_speed_y : Float32 = 128_f32

    # Satisfy MoveController requirement, even though we don't use it here
    def move_speed : Num
      0_f32
    end

    def vertical_scroll_update(dt : Float32, collidables : Array(Collidable) = [] of Collidable, tile_map : TileMap? = nil)
      move_input # sets dx and dy based on input

      # Calculate actual movement amounts for this frame
      move_x = self.dx * strafing_speed_x * dt
      move_y = (auto_scroll_speed + (self.dy * thrust_speed_y)) * dt

      # Move X and collide
      if move_x != 0_f32
        previous_x = self.x
        self.x += move_x
        if collides_with_anything?(collidables, tile_map)
          self.x = previous_x
        end
      end

      # Move Y and collide
      if move_y != 0_f32
        previous_y = self.y
        self.y += move_y
        if collides_with_anything?(collidables, tile_map)
          self.y = previous_y
        end
      end
    end
  end
end
