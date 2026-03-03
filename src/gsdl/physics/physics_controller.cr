require "./body"
require "./collidable"

module GSDL
  module PhysicsController
    include Body
    include Collidable

    # Physics logic:
    # 1. Update acceleration from gravity (if enabled)
    # 2. Update velocity from acceleration
    # 3. Apply drag and friction
    # 4. Move axis by axis and check for collisions
    # 5. Resolve collisions with bounce (restitution)

    def physics_update(dt : Float32, collidables : Array(Collidable) = [] of Collidable, tile_map : TileMap? = nil)
      # 1. Update acceleration from gravity (if enabled)
      if use_gravity
        self.acceleration_x += Physics.gravity.x
        self.acceleration_y += Physics.gravity.y
      end

      # 2. Update velocity from acceleration
      self.velocity_x += acceleration_x * dt
      self.velocity_y += acceleration_y * dt

      # Reset acceleration for next update
      self.acceleration_x = 0
      self.acceleration_y = 0

      # 3. Apply drag (resistance in air/motion)
      if drag > 0
        self.velocity_x *= (1.0_f32 - drag * dt)
        self.velocity_y *= (1.0_f32 - drag * dt)
      end

      # 4 & 5. Move axis by axis and check for collisions with bounce
      physics_move_x(dt, collidables, tile_map)
      physics_move_y(dt, collidables, tile_map)
    end

    def physics_move_x(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?)
      return if velocity_x == 0

      prev_x = self.x
      self.x += velocity_x * dt

      if hit_collidable = collides_with_anything?(collidables, tile_map)
        # Collision on X
        self.x = prev_x
        # Bounce
        self.velocity_x = -velocity_x * restitution

        # Stop if velocity becomes very small (to avoid infinite micro-bouncing)
        self.velocity_x = 0_f32 if velocity_x.abs < 1.0_f32
      end
    end

    def physics_move_y(dt : Float32, collidables : Array(Collidable), tile_map : TileMap?)
      return if velocity_y == 0

      prev_y = self.y
      self.y += velocity_y * dt

      if hit_collidable = collides_with_anything?(collidables, tile_map)
        # Collision on Y
        self.y = prev_y
        # Bounce
        self.velocity_y = -velocity_y * restitution

        # Stop if velocity becomes very small
        self.velocity_y = 0_f32 if velocity_y.abs < 1.0_f32
      end
    end

    private def collides_with_anything?(collidables : Array(GSDL::Collidable), tile_map : GSDL::TileMap?) : GSDL::Collidable?
      collidables.each do |c|
        return c if collides?(c)
      end

      if tm = tile_map
        # Using a small margin or checking specific sides
        if tm.solid_up?(draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h) ||
           tm.solid_down?(draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h) ||
           tm.solid_left?(draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h) ||
           tm.solid_right?(draw_x + collision_bounding_box.x, draw_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          # We don't have a Collidable object for the tile map here, just return self as a dummy
          return self.as(GSDL::Collidable)
        end
      end

      nil
    end

  end
end
