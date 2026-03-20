require "./move_controller"
require "./directionable"
require "./scene_collisions"

module GSDL
  module TopDownController
    enum DirectionalMode
      FourWay
      EightWay
    end

    enum MovementMode
      FreeForm
      GridLocked
    end

    include MoveController
    include Directionable

    # Requirements for the including class
    abstract def grid_size : Num

    # State
    property directional_mode : DirectionalMode = DirectionalMode::EightWay
    property movement_mode : MovementMode = MovementMode::FreeForm

    @grid_target_x : Num = 0_f32
    @grid_target_y : Num = 0_f32
    @is_moving_to_grid : Bool = false

    def moving? : Bool
      @is_moving_to_grid || (dx != 0 || dy != 0)
    end

    def top_down_update(dt : Float32, collidables : Array(Collidable) = [] of Collidable, tile_map : TileMap? = nil)
      Performance.instance.measure("collision") do
        _top_down_update(dt, collidables, tile_map)
      end
    end

    private def _top_down_update(dt : Float32, collidables : Array(Collidable) = [] of Collidable, tile_map : TileMap? = nil)
      if collidables.empty? && tile_map.nil?
        if (scene = root_scene.as?(GSDL::SceneCollisions))
          # Neighborhood rect calculation
          cb = collision_box
          # For TopDown, we might move by speed * dt or grid_size
          # To be safe, we'll use a large enough box.
          # If grid locked, it's grid_size. If free form, it's speed * dt.
          # We'll calculate it based on the current dx/dy if available,
          # or just use a reasonable buffer around the entity.
          speed = move_speed * dt
          mx = dx * speed
          my = dy * speed

          # If grid locked, we might move up to grid_size
          if @movement_mode == MovementMode::GridLocked
            mx = dx * grid_size
            my = dy * grid_size
          end

          nx = (mx < 0 ? cb.x + mx : cb.x).to_f32
          ny = (my < 0 ? cb.y + my : cb.y).to_f32
          nw = (mx.abs + cb.w).to_f32
          nh = (my.abs + cb.h).to_f32

          p = 4.0_f32 # slightly larger padding for top-down
          neighborhood_rect = FRect.new(nx - p, ny - p, nw + p * 2.0_f32, nh + p * 2.0_f32)

          collidables = scene.collision_space.query(neighborhood_rect)
          tile_map = scene.collision_space.tile_map
        end
      end

      case @movement_mode
      when MovementMode::FreeForm
        update_free_form(dt, collidables, tile_map)
      when MovementMode::GridLocked
        update_grid_locked(dt, collidables, tile_map)
      end
    end

    private def update_free_form(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?)
      move_input # sets dx, dy
      normalize_delta_movement
      update_direction
      move_and_collide(dt, collidables, tile_map)
    end

    private def normalize_delta_movement
      if @dx != 0 || @dy != 0
        # Normalization for 8-way diagonal speed consistency
        if @directional_mode == DirectionalMode::EightWay
          length = Math.sqrt(@dx * @dx + @dy * @dy).to_f32
          @dx /= length
          @dy /= length
        elsif @directional_mode == DirectionalMode::FourWay
          # In 4-way, we prioritize one axis if both are pressed
          if @dx != 0 && @dy != 0
            @dy = 0_f32
          end
        end
      end
    end

    private def update_grid_locked(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?)
      if @is_moving_to_grid
        move_towards_grid_target(dt)
      else
        check_grid_input(collidables, tile_map)
      end
    end

    private def check_grid_input(collidables : Array(Collidable), tile_map : TileMap?)
      move_input # sets dx, dy
      normalize_delta_movement

      if dx != 0 || dy != 0
        target_x = self.x + dx * grid_size
        target_y = self.y + dy * grid_size

        # Collision check for target position
        previous_x = self.x
        previous_y = self.y
        self.x = target_x
        self.y = target_y

        can_move = !collides_with_anything?(collidables, tile_map)

        self.x = previous_x
        self.y = previous_y

        if can_move
          update_direction

          @grid_target_x = target_x
          @grid_target_y = target_y
          @is_moving_to_grid = true
        end
      end
    end

    private def move_towards_grid_target(dt : Float32)
      speed = move_speed * dt

      dist_x = @grid_target_x - self.x
      dist_y = @grid_target_y - self.y

      step_x = dist_x.clamp(-speed, speed)
      step_y = dist_y.clamp(-speed, speed)

      self.x += step_x
      self.y += step_y

      if (self.x - @grid_target_x).abs < 0.1 && (self.y - @grid_target_y).abs < 0.1
        self.x = @grid_target_x
        self.y = @grid_target_y
        @is_moving_to_grid = false
      end
    end

    private def update_direction
      if dx > 0
        if dy > 0 && @directional_mode == DirectionalMode::EightWay
          self.direction = Direction::DownRight
        elsif dy < 0 && @directional_mode == DirectionalMode::EightWay
          self.direction = Direction::UpRight
        else
          self.direction = Direction::Right
        end
      elsif dx < 0
        if dy > 0 && @directional_mode == DirectionalMode::EightWay
          self.direction = Direction::DownLeft
        elsif dy < 0 && @directional_mode == DirectionalMode::EightWay
          self.direction = Direction::UpLeft
        else
          self.direction = Direction::Left
        end
      elsif dy > 0
        self.direction = Direction::Down
      elsif dy < 0
        self.direction = Direction::Up
      end
    end
  end
end
