require "../gfx/geo/box"

module GSDL
  class Slider
    include Tweenable

    enum Orientation
      Horizontal
      Vertical
    end

    alias OnChangeCallback = (Float32) ->

    property x : Num = 0
    property y : Num = 0
    property width : Num = 200
    property height : Num = 20
    property min_value : Float32 = 0.0_f32
    property max_value : Float32 = 1.0_f32
    property value : Float32 = 0.5_f32
    
    property background_color : Color = Color::DarkGray
    property track_color : Color = Color::Gray
    property handle_color : Color = Color::White
    property handle_size : Num = 24
    
    property orientation : Orientation = Orientation::Horizontal
    property z_index : Int32 = 0
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    
    property? active : Bool = false
    property on_change : OnChangeCallback?

    getter tweens : Array(Tween) = [] of Tween

    def initialize(
      @x = 0, @y = 0, @width = 200, @height = 20,
      @min_value = 0.0_f32, @max_value = 1.0_f32, @value = 0.5_f32,
      @handle_size = 24,
      @orientation = Orientation::Horizontal,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @on_change = nil,
      @z_index = 0
    )
    end

    def draw_width : Num
      width * scale_x
    end

    def draw_height : Num
      height * scale_y
    end

    def draw_x : Num
      x - (draw_width * origin_x)
    end

    def draw_y : Num
      y - (draw_height * origin_y)
    end

    def origin_x : Float32
      origin[0]
    end

    def origin_y : Float32
      origin[1]
    end

    def scale_x : Num
      scale[0]
    end

    def scale_y : Num
      scale[1]
    end

    def scale_x=(scale_x : Num)
      self.scale = {scale_x, scale_y}
    end

    def scale_y=(scale_y : Num)
      self.scale = {scale_x, scale_y}
    end

    def normalized_value : Float32
      ((value - min_value) / (max_value - min_value)).clamp(0.0_f32, 1.0_f32)
    end

    def set_value_from_normalized(norm : Float32)
      old_val = @value
      @value = min_value + (norm * (max_value - min_value))
      if @value != old_val
        @on_change.try &.call(@value)
      end
    end

    def update(dt : Float32)
      update_tweens(dt)

      if Mouse.just_pressed?(Mouse::ButtonLeft)
        if Mouse.in?(draw_x, draw_y, draw_width, draw_height) || handle_rect.in?(Mouse.x, Mouse.y)
          @active = true
        end
      end

      if Mouse.just_released?(Mouse::ButtonLeft)
        @active = false
      end

      if @active
        if orientation == Orientation::Horizontal
          norm = ((Mouse.x - draw_x) / draw_width).to_f32
          set_value_from_normalized(norm)
        else
          # Vertical slider: bottom is 0, top is 1 usually, or vice versa
          # Let's go with top is max, bottom is min
          norm = 1.0_f32 - ((Mouse.y - draw_y) / draw_height).to_f32
          set_value_from_normalized(norm)
        end
      end
    end

    private def handle_rect : FRect
      norm = normalized_value
      if orientation == Orientation::Horizontal
        hx = draw_x + (draw_width * norm) - (handle_size * scale_x / 2)
        hy = draw_y + (draw_height / 2) - (handle_size * scale_y / 2)
        FRect.new(x: hx.to_f32, y: hy.to_f32, w: (handle_size * scale_x).to_f32, h: (handle_size * scale_y).to_f32)
      else
        hx = draw_x + (draw_width / 2) - (handle_size * scale_x / 2)
        # top is max, bottom is min
        hy = draw_y + (draw_height * (1.0_f32 - norm)) - (handle_size * scale_y / 2)
        FRect.new(x: hx.to_f32, y: hy.to_f32, w: (handle_size * scale_x).to_f32, h: (handle_size * scale_y).to_f32)
      end
    end

    def draw(draw : GSDL::Draw)
      # Track (background)
      bg = Box.new(
        width: width, height: height,
        x: x, y: y,
        color: background_color,
        origin: origin, scale: scale,
        z_index: z_index,
        border_radius: ([width, height].min / 2).to_f32
      )
      bg.draw(draw)

      # Handle
      hr = handle_rect
      handle = Box.new(
        width: handle_size, height: handle_size,
        x: hr.x + hr.w / 2, y: hr.y + hr.h / 2,
        color: handle_color,
        origin: {0.5_f32, 0.5_f32},
        scale: scale,
        z_index: z_index + 1,
        border_radius: (handle_size / 2).to_f32
      )
      handle.draw(draw)
    end
  end
end
