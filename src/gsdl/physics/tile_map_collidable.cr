module GSDL
  module TileMapCollidable
    DEFAULT_GRAVITY = 980.0_f32

    # requires
    abstract def draw_x : Num
    abstract def draw_y : Num
    abstract def draw_width : Num
    abstract def draw_height : Num
    abstract def origin_x : Num
    abstract def origin_y : Num
    abstract def collision_bounding_box : FRect

    property velocity_x = 0.0_f32
    property velocity_y = 0.0_f32
    property gravity = 980.0_f32
    property? grounded = false
    property? use_gravity = false

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
      # We move self.y, but check collision using draw_y + bounding box
      next_y = self.y + dy
      # Calculate what draw_y would be at next_y
      next_draw_y = next_y - (draw_height * origin_y)

      collided = false

      if @velocity_y > 0 # Moving down
        if tile_map.solid_down?(draw_x + collision_bounding_box.x, next_draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          @velocity_y = 0
          # Snap self.y so that the collision box bottom aligns with the tile
          target_draw_y = (((next_draw_y + collision_bounding_box.y + collision_bounding_box.h) / tile_map.tile_height).to_i * tile_map.tile_height - collision_bounding_box.y - collision_bounding_box.h).to_f32
          self.y = target_draw_y + (draw_height * origin_y)
          @grounded = true
          collided = true
        end
      elsif @velocity_y < 0 # Moving up
        if tile_map.solid_up?(draw_x + collision_bounding_box.x, next_draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          @velocity_y = 0
          # Snap self.y so that the collision box top aligns with the tile
          target_draw_y = (((next_draw_y + collision_bounding_box.y) / tile_map.tile_height).to_i + 1) * tile_map.tile_height - collision_bounding_box.y
          self.y = target_draw_y + (draw_height * origin_y)
          collided = true
        end
      end

      self.y = next_y unless collided
    end

    def move_horizontal_and_collide(dt : Float32, tile_map : GSDL::TileMap)
      # horizontal movement and collision
      dx = @velocity_x * dt
      next_x = self.x + dx
      next_draw_x = next_x - (draw_width * origin_x)

      collided = false

      if dx > 0 # Moving right
        if tile_map.solid_right?(next_draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          @velocity_x = 0
          target_draw_x = (((next_draw_x + collision_bounding_box.x + collision_bounding_box.w) / tile_map.tile_width).to_i * tile_map.tile_width - collision_bounding_box.x - collision_bounding_box.w).to_f32
          self.x = target_draw_x + (draw_width * origin_x)
          collided = true
        end
      elsif dx < 0 # Moving left
        if tile_map.solid_left?(next_draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          @velocity_x = 0
          target_draw_x = (((next_draw_x + collision_bounding_box.x) / tile_map.tile_width).to_i + 1) * tile_map.tile_width - collision_bounding_box.x
          self.x = target_draw_x + (draw_width * origin_x)
          collided = true
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
