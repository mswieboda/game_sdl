module GSDL
  class ParticleEmitter
    property x : Float32 = 0_f32
    property y : Float32 = 0_f32
    property rate : Float32 = 0_f32 # Particles per second
    property gravity : Point = Point.new(0, 0)
    property drag : Float32 = 0_f32 # Velocity dampening factor
    property z_index : Int32 = 0

    # Initialization Ranges
    property lifetime_range : Range(Float32, Float32) = 1.0_f32..2.0_f32
    property speed_range : Range(Float32, Float32) = 50.0_f32..100.0_f32
    property angle_range : Range(Float32, Float32) = 0.0_f32..360.0_f32
    property size_range : Range(Float32, Float32) = 2.0_f32..5.0_f32
    property end_size_range : Range(Float32, Float32)? = nil # If set, size will lerp to this
    property rotation_range : Range(Float32, Float32) = 0.0_f32..0.0_f32
    property angular_velocity_range : Range(Float32, Float32) = 0.0_f32..0.0_f32
    property color_range : Tuple(Color, Color) = {Color::White, Color::White}
    property end_color_range : Tuple(Color, Color)? = nil
    property shape : Collidable::Shape = Collidable::Shape::Rect

    # Emitter Area
    property spawn_area_rect : FRect? = nil
    property spawn_area_radius : Float32? = nil

    @particles : Array(Particle)
    @emission_timer : Float32 = 0_f32
    @burst_timer : Float32 = 0_f32
    @burst_count : Int32 = 0
    @burst_interval : Float32 = 0_f32

    def initialize(max_particles : Int32 = 100)
      @particles = Array(Particle).new(max_particles) { Particle.new }
    end

    def burst_timed(count : Int32, interval : Float32)
      @burst_count = count
      @burst_interval = interval
      @burst_timer = 0_f32
    end

    def burst(count : Int32 = 1)
      count.times { spawn_particle }
    end

    def update(dt : Float32)
      # Continuous emission
      if @rate > 0
        @emission_timer += dt
        interval = 1.0_f32 / @rate
        while @emission_timer >= interval
          spawn_particle
          @emission_timer -= interval
        end
      end

      # Timed bursts
      if @burst_count > 0 && @burst_interval > 0
        @burst_timer += dt
        if @burst_timer >= @burst_interval
          burst(@burst_count)
          @burst_timer -= @burst_interval
        end
      end

      @particles.each &.update(dt, @gravity, @drag)
    end

    def draw(draw : Draw)
      @particles.each do |p|
        next unless p.active?

        pos_x = @x + p.position.x
        pos_y = @y + p.position.y
        size = p.current_size
        color = p.current_color

        case p.shape
        when Collidable::Shape::Rect
          draw.rect_fill(
            rect: FRect.new(x: pos_x - size/2, y: pos_y - size/2, w: size, h: size),
            color: color,
            z_index: @z_index
          )
        when Collidable::Shape::Circle
          draw.circle_fill(
            x: pos_x,
            y: pos_y,
            radius: size / 2,
            color: color,
            z_index: @z_index
          )
        else # Pixel
          draw.point(
            x: pos_x,
            y: pos_y,
            color: color,
            z_index: @z_index
          )
        end
      end
    end

    def reset
      @particles.each &.reset
      @emission_timer = 0_f32
      @burst_timer = 0_f32
    end

    private def spawn_particle
      # Find inactive particle
      particle = @particles.find { |p| !p.active? }
      return unless particle

      particle.active = true
      particle.age = 0_f32
      particle.shape = @shape

      # Position within area
      px = 0_f32
      py = 0_f32
      if rect = @spawn_area_rect
        px = Random.rand(rect.x..rect.right)
        py = Random.rand(rect.y..rect.bottom)
      elsif radius = @spawn_area_radius
        angle = Random.rand(0.0_f32..(Math::PI.to_f32 * 2.0_f32))
        r = Math.sqrt(Random.rand).to_f32 * radius
        px = r * Math.cos(angle).to_f32
        py = r * Math.sin(angle).to_f32
      end
      particle.position = Point.new(px, py)

      # Velocity
      speed = Random.rand(@speed_range)
      angle_deg = Random.rand(@angle_range)
      angle_rad = angle_deg * (Math::PI.to_f32 / 180.0_f32)
      particle.velocity = Point.new(
        Math.cos(angle_rad).to_f32 * speed,
        Math.sin(angle_rad).to_f32 * speed
      )

      # Lifetime
      particle.lifetime = Random.rand(@lifetime_range)

      # Size
      particle.start_size = Random.rand(@size_range)
      if range = @end_size_range
        particle.end_size = Random.rand(range)
      else
        particle.end_size = particle.start_size
      end

      # Color
      particle.start_color = lerp_color(@color_range[0], @color_range[1], Random.rand.to_f32)
      if range = @end_color_range
        particle.end_color = lerp_color(range[0], range[1], Random.rand.to_f32)
      else
        particle.end_color = particle.start_color
      end

      # Rotation
      particle.rotation = Random.rand(@rotation_range)
      particle.angular_velocity = Random.rand(@angular_velocity_range)
    end

    private def lerp_color(c1 : Color, c2 : Color, t : Float32) : Color
      c1.lerp(c2, t)
    end
  end
end
