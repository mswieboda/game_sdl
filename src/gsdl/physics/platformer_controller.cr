require "./tile_map_collidable"
require "./directionable"

module GSDL
  module PlatformerController
    include TileMapCollidable
    include Directionable

    # Requirements for the including class
    abstract def move_speed : Num
    abstract def jump_impulse : Num

    def platformer_update(dt : Float32, collidables : Array(Collidable) = [] of Collidable, tile_map : TileMap? = nil, world_bounds : FRect? = nil)
      # 1. Horizontal Input
      dx = 0_f32
      dx -= 1_f32 if Input.action?(:move_left) || Input.action?(:left)
      dx += 1_f32 if Input.action?(:move_right) || Input.action?(:right)
      @velocity_x = dx * move_speed

      # update direction for Directionable
      if dx > 0
        self.direction = Direction::Right
      elsif dx < 0
        self.direction = Direction::Left
      end

      # 2. Jump Input
      if grounded? && (Input.action?(:jump) || Input.action?(:move_up))
        jump(jump_impulse)
      end

      # 3. Movement and Collision
      platformer_move_and_collide(dt, collidables, tile_map, world_bounds)
    end

    def platformer_move_and_collide(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?, world_bounds : FRect?)
      platformer_move_vertical(dt, collidables, tile_map, world_bounds)
      platformer_move_horizontal(dt, collidables, tile_map, world_bounds)
    end

    private def platformer_move_vertical(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?, world_bounds : FRect?)
      if use_gravity?
        @velocity_y += @gravity * dt
      end

      @grounded = false
      dy = @velocity_y * dt
      next_y = self.y + dy
      next_draw_y = next_y - (draw_height * origin_y)

      collided = false

      # 1. TileMap Collision
      if tm = tile_map
        if @velocity_y > 0 # Moving down
          if tm.solid_down?(draw_x + collision_bounding_box.x, next_draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
            @velocity_y = 0
            # Snap self.y so that the collision box bottom aligns with the tile
            target_draw_y = (((next_draw_y + collision_bounding_box.y + collision_bounding_box.h) / tm.tile_height).to_i * tm.tile_height - collision_bounding_box.y - collision_bounding_box.h).to_f32
            self.y = target_draw_y + (draw_height * origin_y)
            @grounded = true
            collided = true
          end
        elsif @velocity_y < 0 # Moving up
          if tm.solid_up?(draw_x + collision_bounding_box.x, next_draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
            @velocity_y = 0
            # Snap self.y so that the collision box top aligns with the tile
            target_draw_y = (((next_draw_y + collision_bounding_box.y) / tm.tile_height).to_i + 1) * tm.tile_height - collision_bounding_box.y
            self.y = target_draw_y + (draw_height * origin_y)
            collided = true
          end
        end
      end

      # 2. Collidables Collision
      unless collided
        previous_y = self.y
        self.y = next_y
        if collidables.any? { |c| self != c && collides?(c) }
          self.y = previous_y
          @velocity_y = 0_f32
          @grounded = true if dy > 0
          collided = true
        else
          self.y = previous_y
        end
      end

      # 3. World Bounds Collision
      if !collided && (bounds = world_bounds)
        next_collision_box_top = next_draw_y + collision_bounding_box.y
        next_collision_box_bottom = next_collision_box_top + collision_bounding_box.h

        if next_collision_box_bottom > bounds.bottom
          @velocity_y = 0_f32
          target_draw_y = bounds.bottom - collision_bounding_box.y - collision_bounding_box.h
          self.y = target_draw_y + (draw_height * origin_y)
          @grounded = true
          collided = true
        elsif next_collision_box_top < bounds.top
          @velocity_y = 0_f32
          target_draw_y = bounds.top - collision_bounding_box.y
          self.y = target_draw_y + (draw_height * origin_y)
          collided = true
        end
      end

      self.y = next_y unless collided
    end

    private def platformer_move_horizontal(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?, world_bounds : FRect?)
      dx = @velocity_x * dt
      next_x = self.x + dx
      next_draw_x = next_x - (draw_width * origin_x)

      collided = false

      # 1. TileMap Collision
      if tm = tile_map
        if dx > 0 # Moving right
          if tm.solid_right?(next_draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
            @velocity_x = 0_f32
            target_draw_x = (((next_draw_x + collision_bounding_box.x + collision_bounding_box.w) / tm.tile_width).to_i * tm.tile_width - collision_bounding_box.x - collision_bounding_box.w).to_f32
            self.x = target_draw_x + (draw_width * origin_x)
            collided = true
          end
        elsif dx < 0 # Moving left
          if tm.solid_left?(next_draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
            @velocity_x = 0_f32
            target_draw_x = (((next_draw_x + collision_bounding_box.x) / tm.tile_width).to_i + 1) * tm.tile_width - collision_bounding_box.x
            self.x = target_draw_x + (draw_width * origin_x)
            collided = true
          end
        end
      end

      # 2. Collidables Collision
      unless collided
        previous_x = self.x
        self.x = next_x
        if collidables.any? { |c| self != c && collides?(c) }
          self.x = previous_x
          @velocity_x = 0_f32
          collided = true
        else
          self.x = previous_x
        end
      end

      # 3. World Bounds Collision
      if !collided && (bounds = world_bounds)
        next_collision_box_left = next_draw_x + collision_bounding_box.x
        next_collision_box_right = next_collision_box_left + collision_bounding_box.w

        if next_collision_box_right > bounds.right
          @velocity_x = 0_f32
          target_draw_x = bounds.right - collision_bounding_box.x - collision_bounding_box.w
          self.x = target_draw_x + (draw_width * origin_x)
          collided = true
        elsif next_collision_box_left < bounds.left
          @velocity_x = 0_f32
          target_draw_x = bounds.left - collision_bounding_box.x
          self.x = target_draw_x + (draw_width * origin_x)
          collided = true
        end
      end

      self.x = next_x unless collided
    end
  end
end
