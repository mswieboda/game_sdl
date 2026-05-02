require "./tile_map_collidable"
require "./directionable"
require "./scene_collisions"

module GSDL
  module PlatformerController
    include TileMapCollidable
    include Directionable

    # Requirements for the including class
    abstract def move_speed : Num
    abstract def jump_impulse : Num

    # Double Jump properties
    property max_jumps : Int32 = 1
    @jump_count : Int32 = 0

    # Wall Jump/Slide properties
    property? can_wall_jump : Bool = false
    property wall_slide_gravity : Float32 = 100.0_f32
    property? wall_sliding : Bool = false
    property wall_jump_impulse_x : Float32 = 300.0_f32
    property wall_jump_impulse_y : Float32 = -400.0_f32

    # Dash properties
    property? can_dash : Bool = false
    property dash_speed : Float32 = 600.0_f32
    property dash_duration : Float32 = 0.2_f32
    property dash_cooldown : Float32 = 0.5_f32
    @dash_timer : Float32 = 0_f32
    @dash_cooldown_timer : Float32 = 0_f32
    property? dashing : Bool = false
    @dash_direction : Float32 = 0_f32

    # Crouching properties
    property? can_crouch : Bool = false
    property? crouching : Bool = false
    property crouch_speed_multiplier : Float32 = 0.5_f32

    def platformer_update(dt : Float32, collidables : Array(Collidable) = [] of Collidable, tile_map : TileMap? = nil, world_bounds : FRect? = nil)
      Performance.instance.measure("collision") do
        _platformer_update(dt, collidables, tile_map, world_bounds)
      end
    end

    private def _platformer_update(dt : Float32, collidables : Array(Collidable) = [] of Collidable, tile_map : TileMap? = nil, world_bounds : FRect? = nil)
      if collidables.empty? && tile_map.nil? && world_bounds.nil?
        if (scene = root_scene.as?(GSDL::SceneCollisions))
          # Neighborhood rect calculation
          # We'll use a conservative buffer around the entity's current bounds
          # to capture anything it might collide with this frame (jumping, dashing, etc).
          cb = collision_box
          # A fixed buffer of 128 is generally safe for most speeds at 60fps
          p = 128.0_f32
          neighborhood_rect = FRect.new(cb.x - p, cb.y - p, cb.w + p * 2.0_f32, cb.h + p * 2.0_f32)

          collidables = scene.collision_space.query(neighborhood_rect)
          tile_map = scene.collision_space.tile_map
          world_bounds = scene.collision_space.space_bounds
        end
      end

      update_timers(dt)

      # 0. Handle Dashing
      if dashing?
        @velocity_x = @dash_direction * dash_speed
        @velocity_y = 0_f32
        platformer_move_and_collide(dt, collidables, tile_map, world_bounds)
        return
      end

      # 1. Crouching
      if can_crouch?
        @crouching = Input.action?(:crouch) || Input.action?(:move_down)
      end

      # 2. Horizontal Input
      dx = 0_f32
      dx -= 1_f32 if Input.action?(:move_left) || Input.action?(:left)
      dx += 1_f32 if Input.action?(:move_right) || Input.action?(:right)

      current_speed = move_speed.to_f32
      current_speed *= crouch_speed_multiplier if crouching?

      @velocity_x = dx * current_speed

      # update direction for Directionable
      if dx > 0
        self.direction = Direction::Right
      elsif dx < 0
        self.direction = Direction::Left
      end

      # 3. Dash Input
      if can_dash? && @dash_cooldown_timer <= 0 && Input.action?(:dash)
        start_dash
        return
      end

      # 4. Jump Input
      if Input.action?(:jump) || Input.action?(:move_up)
        if grounded?
          jump(jump_impulse.to_f32)
          @jump_count = 1
        elsif wall_sliding? || (can_wall_jump? && against_wall?(dx, tile_map, collidables))
          wall_jump
          @jump_count = 1
        elsif @jump_count < max_jumps
          # Allow air jump
          @velocity_y = jump_impulse.to_f32
          @grounded = false
          @jump_count += 1
        end
      end

      # Reset jump count if grounded
      @jump_count = 0 if grounded?

      # 5. Wall Slide Detection
      @wall_sliding = false
      if can_wall_jump? && !grounded? && @velocity_y > 0
        # Check if we are against a wall in the direction we are moving or facing
        if against_wall?(dx, tile_map, collidables)
           @wall_sliding = true
        end
      end

      # 6. Movement and Collision
      platformer_move_and_collide(dt, collidables, tile_map, world_bounds)
    end

    private def update_timers(dt : Float32)
      if @dash_timer > 0
        @dash_timer -= dt
        @dashing = false if @dash_timer <= 0
      end

      if @dash_cooldown_timer > 0
        @dash_cooldown_timer -= dt
      end
    end

    private def start_dash
      @dashing = true
      @dash_timer = dash_duration
      @dash_cooldown_timer = dash_cooldown

      # Dash in current direction
      @dash_direction = direction.right? ? 1_f32 : -1_f32
    end

    private def wall_jump
      # Jump away from the wall
      @velocity_x = (direction.right? ? -1_f32 : 1_f32) * wall_jump_impulse_x
      @velocity_y = wall_jump_impulse_y
      @grounded = false
      @wall_sliding = false

      # Flip direction when jumping off wall
      self.direction = direction.right? ? Direction::Left : Direction::Right
    end

    private def against_wall?(dx : Float32, tile_map : TileMap?, collidables : Array(Collidable)) : Bool
      # We check slightly to the left or right of our collision box
      check_dx = direction.right? ? 1 : -1

      # Check TileMap
      if tm = tile_map
        if direction.right?
          return true if tm.solid_right?(render_x + collision_bounding_box.x, render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
        else
          return true if tm.solid_left?(render_x + collision_bounding_box.x, render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
        end
      end

      # Check Collidables
      previous_x = self.x
      self.x += check_dx
      collided = collidables.any? { |c| c != self && c.solid? && collides?(c) }
      self.x = previous_x

      collided
    end

    def platformer_move_and_collide(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?, world_bounds : FRect?)
      platformer_move_vertical(dt, collidables, tile_map, world_bounds)
      platformer_move_horizontal(dt, collidables, tile_map, world_bounds)
    end

    private def platformer_move_vertical(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?, world_bounds : FRect?)
      if use_gravity?
        gravity_to_use = wall_sliding? ? wall_slide_gravity : @gravity
        @velocity_y += gravity_to_use * dt

        # Terminal velocity for wall slide
        if wall_sliding? && @velocity_y > wall_slide_gravity
          @velocity_y = wall_slide_gravity
        end
      end

      @grounded = false
      dy = @velocity_y * dt
      next_y = self.y + dy
      next_render_y = next_y - (render_height * origin_y)

      collided = false

      # 1. TileMap Collision
      if tm = tile_map
        if @velocity_y > 0 # Moving down
          if tm.solid_down?(render_x + collision_bounding_box.x, next_render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
            @velocity_y = 0
            # Snap self.y so that the collision box bottom aligns with the tile
            target_render_y = (((next_render_y + collision_bounding_box.y + collision_bounding_box.h) / tm.tile_height).to_i * tm.tile_height - collision_bounding_box.y - collision_bounding_box.h).to_f32
            self.y = target_render_y + (render_height * origin_y)
            @grounded = true
            collided = true
          end
        elsif @velocity_y < 0 # Moving up
          if tm.solid_up?(render_x + collision_bounding_box.x, next_render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
            @velocity_y = 0
            # Snap self.y so that the collision box top aligns with the tile
            target_render_y = (((next_render_y + collision_bounding_box.y) / tm.tile_height).to_i + 1) * tm.tile_height - collision_bounding_box.y
            self.y = target_render_y + (render_height * origin_y)
            collided = true
          end
        end
      end

      # 2. Collidables Collision
      unless collided
        previous_y = self.y
        self.y = next_y
        if collidables.any? { |c| c != self && c.solid? && collides?(c) }
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
        next_collision_box_top = next_render_y + collision_bounding_box.y
        next_collision_box_bottom = next_collision_box_top + collision_bounding_box.h

        if next_collision_box_bottom > bounds.bottom
          @velocity_y = 0_f32
          target_render_y = bounds.bottom - collision_bounding_box.y - collision_bounding_box.h
          self.y = target_render_y + (render_height * origin_y)
          @grounded = true
          collided = true
        elsif next_collision_box_top < bounds.top
          @velocity_y = 0_f32
          target_render_y = bounds.top - collision_bounding_box.y
          self.y = target_render_y + (render_height * origin_y)
          collided = true
        end
      end

      self.y = next_y unless collided
    end

    private def platformer_move_horizontal(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?, world_bounds : FRect?)
      dx = @velocity_x * dt
      next_x = self.x + dx
      next_render_x = next_x - (render_width * origin_x)

      collided = false

      # 1. TileMap Collision
      if tm = tile_map
        if dx > 0 # Moving right
          if tm.solid_right?(next_render_x + collision_bounding_box.x, render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
            @velocity_x = 0_f32
            target_render_x = (((next_render_x + collision_bounding_box.x + collision_bounding_box.w) / tm.tile_width).to_i * tm.tile_width - collision_bounding_box.x - collision_bounding_box.w).to_f32
            self.x = target_render_x + (render_width * origin_x)
            collided = true
          end
        elsif dx < 0 # Moving left
          if tm.solid_left?(next_render_x + collision_bounding_box.x, render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
            @velocity_x = 0_f32
            target_render_x = (((next_render_x + collision_bounding_box.x) / tm.tile_width).to_i + 1) * tm.tile_width - collision_bounding_box.x
            self.x = target_render_x + (render_width * origin_x)
            collided = true
          end
        end
      end

      # 2. Collidables Collision
      unless collided
        previous_x = self.x
        self.x = next_x
        if collidables.any? { |c| c != self && c.solid? && collides?(c) }
          self.x = previous_x
          @velocity_x = 0_f32
          collided = true
        else
          self.x = previous_x
        end
      end

      # 3. World Bounds Collision
      if !collided && (bounds = world_bounds)
        next_collision_box_left = next_render_x + collision_bounding_box.x
        next_collision_box_right = next_collision_box_left + collision_bounding_box.w

        if next_collision_box_right > bounds.right
          @velocity_x = 0_f32
          target_render_x = bounds.right - collision_bounding_box.x - collision_bounding_box.w
          self.x = target_render_x + (render_width * origin_x)
          collided = true
        elsif next_collision_box_left < bounds.left
          @velocity_x = 0_f32
          target_render_x = bounds.left - collision_bounding_box.x
          self.x = target_render_x + (render_width * origin_x)
          collided = true
        end
      end

      self.x = next_x unless collided
    end
  end
end
