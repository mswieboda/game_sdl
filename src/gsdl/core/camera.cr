module GSDL
  class Camera
    enum Type
      CenterOnTarget
      CenterOnTargetWithBoundary
      Manual
    end

    property type : Type = Type::CenterOnTarget

    property x : Num = 0_f32
    property y : Num = 0_f32
    property width : Num
    property height : Num

    # Target coordinates
    property target_x : Num? = nil
    property target_y : Num? = nil

    # Boundary configuration
    property boundary_x : Num = 0_f32
    property boundary_y : Num = 0_f32
    property boundary_width : Num = 0_f32
    property boundary_height : Num = 0_f32

    # Input movement configuration
    property speed : Num = 300_f32
    property input_up : Symbol = :camera_up
    property input_down : Symbol = :camera_down
    property input_left : Symbol = :camera_left
    property input_right : Symbol = :camera_right

    def initialize(@width : Num, @height : Num)
    end

    def update(dt : Float32)
      case @type
      when Type::CenterOnTarget
        update_center_on_target
      when Type::CenterOnTargetWithBoundary
        update_center_on_target
        apply_boundary
      when Type::Manual
        update_manual_movement(dt)
      end
    end

    def look_at(tx : Num, ty : Num)
      @target_x = tx
      @target_y = ty
    end

    def look_at(sprite : SpriteBase)
      look_at(sprite.x, sprite.y)
    end

    def set_boundary(x : Num, y : Num, width : Num, height : Num)
      @boundary_x = x
      @boundary_y = y
      @boundary_width = width
      @boundary_height = height
    end

    def set_boundary(rect : Rect | FRect)
      set_boundary(rect.x, rect.y, rect.width, rect.height)
    end

    def set_boundary(tile_map : TileMap)
      set_boundary(0, 0, tile_map.width, tile_map.height)
    end

    private def update_center_on_target
      if (tx = @target_x) && (ty = @target_y)
        @x = tx - (@width / 2_f32)
        @y = ty - (@height / 2_f32)
      end
    end

    private def apply_boundary
      if @boundary_width > 0 && @boundary_height > 0
        if @boundary_width > @width
          @x = @boundary_x if @x < @boundary_x
          @x = @boundary_x + @boundary_width - @width if @x + @width > @boundary_x + @boundary_width
        else
          @x = @boundary_x + (@boundary_width / 2_f32) - (@width / 2_f32)
        end

        if @boundary_height > @height
          @y = @boundary_y if @y < @boundary_y
          @y = @boundary_y + @boundary_height - @height if @y + @height > @boundary_y + @boundary_height
        else
          @y = @boundary_y + (@boundary_height / 2_f32) - (@height / 2_f32)
        end
      end
    end

    private def update_manual_movement(dt : Float32)
      dx = 0_f32
      dy = 0_f32

      dy -= 1_f32 if Input.action?(@input_up)
      dy += 1_f32 if Input.action?(@input_down)
      dx -= 1_f32 if Input.action?(@input_left)
      dx += 1_f32 if Input.action?(@input_right)

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
