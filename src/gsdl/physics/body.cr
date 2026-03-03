module GSDL
  module Body
    # Requires x, y and collision box
    abstract def x : Num
    abstract def y : Num
    abstract def x=(value : Num)
    abstract def y=(value : Num)
    abstract def collision_bounding_box : FRect

    property velocity_x : Float32 = 0_f32
    property velocity_y : Float32 = 0_f32
    property acceleration_x : Float32 = 0_f32
    property acceleration_y : Float32 = 0_f32
    property friction : Float32 = 0_f32      # Constant deceleration when on ground
    property drag : Float32 = 0_f32          # Air resistance multiplier (0 to 1)
    property restitution : Float32 = 0.5_f32 # Bounciness (0 to 1)
    property mass : Float32 = 1.0_f32
    property use_gravity : Bool = true

    def apply_force(fx : Num, fy : Num)
      @acceleration_x += fx.to_f32 / mass
      @acceleration_y += fy.to_f32 / mass
    end

    def apply_impulse(ix : Num, iy : Num)
      @velocity_x += ix.to_f32 / mass
      @velocity_y += iy.to_f32 / mass
    end
  end
end
