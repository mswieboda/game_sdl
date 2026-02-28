module GSDL
  class Camera
    enum Type
      CenterOnTarget
      CenterOnTargetWithBoundary
      InputMovement
    end

    property type : Type = Type::CenterOnTarget

    property x : Float32 = 0_f32
    property y : Float32 = 0_f32
    property width : Int32
    property height : Int32

    # Target coordinates
    property target_x : Float32? = nil
    property target_y : Float32? = nil

    # Boundary configuration
    property boundary_x : Float32 = 0_f32
    property boundary_y : Float32 = 0_f32
    property boundary_width : Float32 = 0_f32
    property boundary_height : Float32 = 0_f32

    # Input movement configuration
    property speed : Float32 = 300_f32
    property input_up : Symbol = :camera_up
    property input_down : Symbol = :camera_down
    property input_left : Symbol = :camera_left
    property input_right : Symbol = :camera_right

    def initialize(@width : Int32, @height : Int32)
    end

    def update(dt : Float32)
      case @type
      when Type::CenterOnTarget
        update_center_on_target
      when Type::CenterOnTargetWithBoundary
        update_center_on_target
        apply_boundary
      when Type::InputMovement
        update_input_movement(dt)
      end
    end

    def look_at(tx : Number, ty : Number)
      @target_x = tx.to_f32
      @target_y = ty.to_f32
    end

    def set_boundary(bx : Float32, by : Float32, bw : Float32, bh : Float32)
      @boundary_x = bx
      @boundary_y = by
      @boundary_width = bw
      @boundary_height = bh
    end

    private def update_center_on_target
      if (tx = @target_x) && (ty = @target_y)
        @x = tx - (@width / 2.0_f32)
        @y = ty - (@height / 2.0_f32)
      end
    end

    private def apply_boundary
      if @x < @boundary_x
        @x = @boundary_x
      elsif @x + @width > @boundary_x + @boundary_width
        @x = @boundary_x + @boundary_width - @width
      end

      if @y < @boundary_y
        @y = @boundary_y
      elsif @y + @height > @boundary_y + @boundary_height
        @y = @boundary_y + @boundary_height - @height
      end
    end

    private def update_input_movement(dt : Float32)
      dx = 0_f32
      dy = 0_f32

      dy -= 1_f32 if GSDL::Input.action?(@input_up)
      dy += 1_f32 if GSDL::Input.action?(@input_down)
      dx -= 1_f32 if GSDL::Input.action?(@input_left)
      dx += 1_f32 if GSDL::Input.action?(@input_right)

      if dx != 0_f32 || dy != 0_f32
        # Normalize diagonal movement
        len = Math.sqrt(dx * dx + dy * dy)
        dx /= len
        dy /= len

        @x += dx * @speed * dt
        @y += dy * @speed * dt
      end
    end
  end
end
