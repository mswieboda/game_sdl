module GSDL
  class Particle
    property? active : Bool = false
    property position : Point = Point.new(0, 0)
    property velocity : Point = Point.new(0, 0)
    property rotation : Float32 = 0_f32
    property angular_velocity : Float32 = 0_f32
    property age : Float32 = 0_f32
    property lifetime : Float32 = 0_f32
    property start_size : Float32 = 1_f32
    property end_size : Float32 = 1_f32
    property start_color : Color = Color::White
    property end_color : Color = Color::White
    property shape : Collidable::Shape = Collidable::Shape::Rect

    def initialize
    end

    def reset
      @active = false
      @age = 0_f32
    end

    def update(dt : Float32, gravity : Point, drag : Float32)
      return unless @active

      @age += dt
      if @age >= @lifetime
        @active = false
        return
      end

      # Forces
      @velocity += gravity * dt
      if drag > 0
        @velocity *= (1.0_f32 - drag * dt)
      end

      # Motion
      @position += @velocity * dt
      @rotation += @angular_velocity * dt
    end

    def current_size : Float32
      t = @age / @lifetime
      MathUtils.lerp(@start_size, @end_size, t)
    end

    def current_color : Color
      t = @age / @lifetime
      @start_color.lerp(@end_color, t)
    end
  end
end
