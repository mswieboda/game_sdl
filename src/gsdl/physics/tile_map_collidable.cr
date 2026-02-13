module GSDL
  module TileMapCollidable
    DEFAULT_GRAVITY = 980.0_f32

    property velocity_x = 0.0_f32
    property velocity_y = 0.0_f32
    property gravity = 980.0_f32
    property? grounded = false
    property? use_gravity = false

    # This method requires the including class to have:
    # - x, y properties
    # - collision_bounding_box : SDL3::FRect
    def move_and_collide(dt : Float32, tile_map : GSDL::TileMap)
      move_vertical_and_collide(dt, tile_map)
      move_horizontal_and_collide(dt, tile_map)
    end

    def move_vertical_and_collide(dt : Float32, tile_map : GSDL::TileMap)
      # vertical movement and collision
      if use_gravity?
        @velocity_y += @gravity * dt
      end

      @grounded = false
      dy = @velocity_y * dt
      next_y = self.y + dy
      collided = false

      if @velocity_y > 0 # Moving down
        if tile_map.solid_down?(self.x + collision_bounding_box.x, next_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          @velocity_y = 0
          self.y = (((next_y + collision_bounding_box.y + collision_bounding_box.h) / tile_map.tile_height).to_i * tile_map.tile_height - collision_bounding_box.y - collision_bounding_box.h).to_f32
          @grounded = true
          collided = true
        end
      elsif @velocity_y < 0 # Moving up
        if tile_map.solid_up?(self.x + collision_bounding_box.x, next_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          @velocity_y = 0
          self.y = (((next_y + collision_bounding_box.y) / tile_map.tile_height).to_i + 1) * tile_map.tile_height - collision_bounding_box.y
          collided = true
        end
      end

      self.y = next_y unless collided
    end

    def move_horizontal_and_collide(dt : Float32, tile_map : GSDL::TileMap)
      # horizontal movement and collision
      dx = @velocity_x * dt
      next_x = self.x + dx
      collided = false

      if dx > 0 # Moving right
        if tile_map.solid_right?(next_x + collision_bounding_box.x, self.y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          self.x = (((next_x + collision_bounding_box.x + collision_bounding_box.w) / tile_map.tile_width).to_i * tile_map.tile_width - collision_bounding_box.x - collision_bounding_box.w).to_f32
          collided = true
          @velocity_x = 0
        end
      elsif dx < 0 # Moving left
        if tile_map.solid_left?(next_x + collision_bounding_box.x, self.y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          self.x = (((next_x + collision_bounding_box.x) / tile_map.tile_width).to_i + 1) * tile_map.tile_width - collision_bounding_box.x
          collided = true
          @velocity_x = 0
        end
      end

      self.x = next_x unless collided
    end

    def jump(impulse : Float32)
      if grounded?
        @velocity_y = impulse
        @grounded = false
      end
    end
  end
end
