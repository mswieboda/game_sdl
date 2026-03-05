require "./tween"
require "./tweenable"

module GSDL
  class Camera
    include Tweenable

    enum Type
      CenterOnTarget
      CenterOnTargetWithBoundary
      Manual
    end

    property type : Type = Type::CenterOnTarget

    property offset_x : Float32 = 0_f32
    property offset_y : Float32 = 0_f32

    property tweens : Array(Tween) = [] of Tween

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

    @zoom : Float32 = 1.0_f32
    @x : Float32 = 0_f32
    @y : Float32 = 0_f32

    def initialize(@width : Num, @height : Num)
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

    def z_index : Int32; 0; end
    def z_index=(z_index : Int32); end

    def scale : Tuple(Num, Num)
      {@zoom, @zoom}
    end

    def scale=(scale : Tuple(Num, Num))
      self.zoom = scale[0].to_f32
    end

    def scale_x : Num; @zoom; end
    def scale_x=(scale_x : Num); self.zoom = scale_x.to_f32; end

    def scale_y : Num; @zoom; end
    def scale_y=(scale_y : Num); self.zoom = scale_y.to_f32; end

    def x : Float32
      @x + @offset_x
    end

    def x=(x : Num)
      @x = x.to_f32
    end

    def y : Float32
      @y + @offset_y
    end

    def y=(y : Num)
      @y = y.to_f32
    end

    def zoom
      @zoom
    end

    def zoom=(new_zoom : Float32)
      return if @zoom == new_zoom

      # Calculate the world coordinates of the center of the current camera view
      center_x = @x + (@width / (2_f32 * @zoom))
      center_y = @y + (@height / (2_f32 * @zoom))

      @zoom = new_zoom

      # Update @x and @y so that center_x and center_y are still at the center of the view
      @x = center_x - (@width / (2_f32 * @zoom))
      @y = center_y - (@height / (2_f32 * @zoom))
    end

    def shake(duration : Float32, intensity : Float32 = 10_f32)
      @offset_x = 0_f32
      @offset_y = 0_f32

      steps = [] of Hash(String, Tween::SequenceValue)

      num_steps = (duration / 0.05).to_i
      num_steps = 1 if num_steps < 1
      step_duration = duration / num_steps

      num_steps.times do |i|
        current_intensity = intensity * (1.0_f32 - (i.to_f32 / num_steps.to_f32))
        dx = (Random.rand * 2.0 - 1.0) * current_intensity
        dy = (Random.rand * 2.0 - 1.0) * current_intensity

        steps << {
          "duration" => step_duration.as(Tween::SequenceValue),
          "offset_x" => dx.as(Tween::SequenceValue),
          "offset_y" => dy.as(Tween::SequenceValue)
        }
      end

      steps << {
        "duration" => 0.05_f32.as(Tween::SequenceValue),
        "offset_x" => 0_f32.as(Tween::SequenceValue),
        "offset_y" => 0_f32.as(Tween::SequenceValue)
      }

      t = tween
      t.add_sequence(steps)
      t.start
    end

    def update(dt : Float32)
      update_tweens(dt)
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

    private def update_center_on_target
      if (tx = @target_x) && (ty = @target_y)
        @x = tx - (@width / (2_f32 * @zoom))
        @y = ty - (@height / (2_f32 * @zoom))
      end
    end

    private def apply_boundary
      effective_width = @width / @zoom
      effective_height = @height / @zoom

      if @boundary_width > 0 && @boundary_height > 0
        if @boundary_width > effective_width
          @x = @boundary_x.to_f32 if @x < @boundary_x
          @x = @boundary_x.to_f32 + @boundary_width - effective_width if @x + effective_width > @boundary_x.to_f32 + @boundary_width
        else
          @x = @boundary_x.to_f32 + (@boundary_width / 2_f32) - (effective_width / 2_f32)
        end

        if @boundary_height > effective_height
          @y = @boundary_y.to_f32 if @y < @boundary_y
          @y = @boundary_y.to_f32 + @boundary_height - effective_height if @y + effective_height > @boundary_y.to_f32 + @boundary_height
        else
          @y = @boundary_y.to_f32 + (@boundary_height / 2_f32) - (effective_height / 2_f32)
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

    # TODO: required if trying to draw Tweenable objects
    # using `obj.each(&.draw(draw))`
    # think of a better solution
    def draw(draw : Draw)
    end
  end
end
