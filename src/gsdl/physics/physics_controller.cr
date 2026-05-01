require "./body"
require "./collidable"
require "./scene_collisions"

module GSDL
  module PhysicsController
    include Body
    include Collidable

    # Default implementation for non-Entity objects
    def root_scene : Scene?
      nil
    end

    # Physics logic:
    # 1. Update acceleration from gravity (if enabled)
    # 2. Update velocity from acceleration
    # 3. Apply drag and friction
    # 4. Move axis by axis and check for collisions
    # 5. Resolve collisions with bounce (restitution)

    def physics_update(dt : Float32, collidables : Array(GSDL::Collidable) = [] of Collidable, tile_map : TileMap? = nil)
      Performance.instance.measure("collision") do
        _physics_update(dt, collidables, tile_map)
      end
    end

    private def _physics_update(dt : Float32, collidables : Array(GSDL::Collidable) = [] of Collidable, tile_map : TileMap? = nil)
      return unless physics_enabled?

      if collidables.empty? && tile_map.nil?
        if (scene = self.root_scene.as?(GSDL::SceneCollisions))
          # Neighborhood rect calculation
          # We'll use a conservative buffer around the entity's current bounds
          # to capture anything it might collide with this frame.
          cb = collision_box
          # A fixed buffer of 128 is generally safe for most speeds at 60fps
          p = 128.0_f32
          neighborhood_rect = FRect.new(cb.x - p, cb.y - p, cb.w + p * 2.0_f32, cb.h + p * 2.0_f32)

          collidables = scene.collision_space.query(neighborhood_rect)
          tile_map = scene.collision_space.tile_map
        end
      end


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

      # 6. Resolve any remaining overlap (e.g. from rotation)
      physics_resolve_overlap(collidables, tile_map)
    end

    def resolve_collision(other : GSDL::Collidable, info : GSDL::Collidable::CollisionInfo)
      if other.is_a?(GSDL::Body)
        # Dynamic vs Dynamic collision
        body2 = other.as(GSDL::Body)
        m1 = self.mass
        m2 = body2.mass

        # 1. Separation
        # Total penetration needs to be resolved. Push both away based on mass.
        # If one is much heavier, it moves less.
        total_inv_mass = (1.0_f32 / m1) + (1.0_f32 / m2)

        # Push this body
        self.x += info.normal.x * info.penetration * ((1.0_f32 / m1) / total_inv_mass)
        self.y += info.normal.y * info.penetration * ((1.0_f32 / m1) / total_inv_mass)

        # Push other body (opposite direction)
        body2.x -= info.normal.x * info.penetration * ((1.0_f32 / m2) / total_inv_mass)
        body2.y -= info.normal.y * info.penetration * ((1.0_f32 / m2) / total_inv_mass)

        # 2. Velocity resolution (Impulse)
        v1 = Point.new(velocity_x, velocity_y)
        v2 = Point.new(body2.velocity_x, body2.velocity_y)
        relative_velocity = v1 - v2

        # Relative velocity along normal
        v_dot_n = relative_velocity.dot(info.normal)

        # Only resolve if objects are moving towards each other
        if v_dot_n < 0
          e = Math.min(restitution, body2.restitution)

          # Impulse scalar
          j = -(1.0_f32 + e) * v_dot_n
          j /= total_inv_mass

          impulse = info.normal * j

          self.velocity_x += impulse.x / m1
          self.velocity_y += impulse.y / m1

          body2.velocity_x -= impulse.x / m2
          body2.velocity_y -= impulse.y / m2

          # 3. Friction (Dynamic)
          # relative tangent velocity
          v_normal_comp = info.normal * v_dot_n
          v_tan = relative_velocity - v_normal_comp

          if v_tan.length > 0
            f = Math.min(friction, body2.friction)
            reduction = Math.min(1.0_f32, f)
            friction_impulse = v_tan * -reduction

            # Simple friction application
            self.velocity_x += friction_impulse.x / 2.0_f32
            self.velocity_y += friction_impulse.y / 2.0_f32
            body2.velocity_x -= friction_impulse.x / 2.0_f32
            body2.velocity_y -= friction_impulse.y / 2.0_f32
          end
        end
      else
        # Dynamic vs Static (original logic)
        # Separate object
        self.x += info.normal.x * info.penetration
        self.y += info.normal.y * info.penetration

        # Velocity vector
        v = Point.new(velocity_x, velocity_y)

        # Dot product of velocity and normal (velocity component into the surface)
        v_dot_n = v.dot(info.normal)

        # Only bounce if objects are moving towards each other
        if v_dot_n < 0
          # 1. Handle Bounce (Normal impulse)
          # Reflection vector: v_new = v - (1 + restitution) * (v . n) * n
          bounce_impulse = info.normal * (-(1.0_f32 + restitution) * v_dot_n)

          # 2. Handle Friction (Tangent impulse)
          v_normal_component = info.normal * v_dot_n
          v_tangent = v - v_normal_component

          friction_impulse = Point.new(0, 0)
          if friction > 0 && v_tangent.length > 0
            reduction = Math.min(1.0_f32, friction)
            friction_impulse = v_tangent * -reduction
          end

          self.velocity_x += bounce_impulse.x + friction_impulse.x
          self.velocity_y += bounce_impulse.y + friction_impulse.y
        end
      end
    end

    def physics_move_x(dt : Float32, collidables : Array(GSDL::Collidable), tile_map : GSDL::TileMap?)
      return if velocity_x == 0

      prev_x = self.x
      self.x += velocity_x * dt

      if hit_collidable = collides_with_anything?(collidables, tile_map)
        info = self.collision_info(hit_collidable)
        if info.hit?
          self.x = prev_x
          resolve_collision(hit_collidable, info)
        end
      end
    end

    def physics_move_y(dt : Float32, collidables : Array(GSDL::Collidable), tile_map : GSDL::TileMap?)
      return if velocity_y == 0

      prev_y = self.y
      self.y += velocity_y * dt

      if hit_collidable = collides_with_anything?(collidables, tile_map)
        info = self.collision_info(hit_collidable)
        if info.hit?
          self.y = prev_y
          resolve_collision(hit_collidable, info)
        end
      end
    end

    def physics_resolve_overlap(collidables : Array(GSDL::Collidable), tile_map : GSDL::TileMap?)
      # Check for overlap and push out without adding velocity
      collidables.each do |other|
        next if other == self
        next unless other.solid?
        info = self.collision_info(other)
        if info.hit?
          self.x += info.normal.x * info.penetration
          self.y += info.normal.y * info.penetration

          # cancel velocity in direction of collision
          v = Point.new(velocity_x, velocity_y)
          v_dot_n = v.dot(info.normal)
          if v_dot_n < 0
            self.velocity_x -= info.normal.x * v_dot_n
            self.velocity_y -= info.normal.y * v_dot_n
          end
        end
      end
    end

    private def collides_with_anything?(collidables : Array(GSDL::Collidable), tile_map : GSDL::TileMap?) : GSDL::Collidable?
      collidables.each do |c|
        return c if c != self && c.solid? && collides?(c)
      end

      if tm = tile_map
        # Using a small margin or checking specific sides
        if tm.solid_up?(render_x + collision_bounding_box.x, render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h) ||
           tm.solid_down?(render_x + collision_bounding_box.x, render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h) ||
           tm.solid_left?(render_x + collision_bounding_box.x, render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h) ||
           tm.solid_right?(render_x + collision_bounding_box.x, render_y + collision_bounding_box.y, collision_bounding_box.w, collision_bounding_box.h)
          # We don't have a Collidable object for the tile map here, just return self as a dummy
          return self.as(GSDL::Collidable)
        end
      end

      nil
    end

  end
end
