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

    property background_color : Color = ColorScheme.get(:alt)
    property track_color : Color = ColorScheme.get(:main)
    property handle_color : Color = ColorScheme.get(:ui_text)
    property handle_size : Num = 24

    property orientation : Orientation = Orientation::Horizontal
    property z_index : Int32 = 0
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    property? draw_relative_to_camera : Bool = false

    property? active : Bool = false
    property on_change : OnChangeCallback?

    getter tweens : Array(Tween) = [] of Tween

    def initialize(
      @x = 0,
      @y = 0,
      @width = 200,
      @height = 20,
      @min_value = 0.0_f32, @max_value = 1.0_f32, @value = 0.5_f32,
      @handle_size = 24,
      @orientation = Orientation::Horizontal,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @on_change = nil,
      @z_index = 0,
      @draw_relative_to_camera = false
    )
    end

    @[AlwaysInline]
    def render_x : Num
      global_x - (render_width * origin_x)
    end

    @[AlwaysInline]
    def render_y : Num
      global_y - (render_height * origin_y)
    end

    @[AlwaysInline]
    def render_width : Num
      width * scale_x
    end

    @[AlwaysInline]
    def render_height : Num
      height * scale_y
    end

    @[AlwaysInline]
    def global_x : Num
      x
    end

    @[AlwaysInline]
    def global_y : Num
      y
    end

    @[AlwaysInline]
    def origin_x : Float32
      origin[0]
    end

    @[AlwaysInline]
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

    def screen_x : Num
      draw_relative_to_camera? ? (render_x - Game.camera.x) * Game.camera.zoom : render_x
    end

    def screen_y : Num
      draw_relative_to_camera? ? (render_y - Game.camera.y) * Game.camera.zoom : render_y
    end

    def update(dt : Float32)
      update_tweens(dt)

      sx = screen_x
      sy = screen_y
      sw = draw_relative_to_camera? ? render_width * Game.camera.zoom : render_width
      sh = draw_relative_to_camera? ? render_height * Game.camera.zoom : render_height

      if Mouse.just_pressed?(Mouse::ButtonLeft)
        if Mouse.in?(sx, sy, sw, sh) || handle_rect.in?(Mouse.x, Mouse.y)
          @active = true
        end
      end

      if Mouse.just_released?(Mouse::ButtonLeft)
        @active = false
      end

      if @active
        if orientation == Orientation::Horizontal
          norm = ((Mouse.x - sx) / sw).to_f32
          set_value_from_normalized(norm)
        else
          # Vertical slider: bottom is 0, top is 1 usually, or vice versa
          # Let's go with top is max, bottom is min
          norm = 1.0_f32 - ((Mouse.y - sy) / sh).to_f32
          set_value_from_normalized(norm)
        end
      end
    end

    private def handle_rect : FRect
      norm = normalized_value
      sx = screen_x
      sy = screen_y
      sw = draw_relative_to_camera? ? render_width * Game.camera.zoom : render_width
      sh = draw_relative_to_camera? ? render_height * Game.camera.zoom : render_height
      h_size_x = draw_relative_to_camera? ? handle_size * scale_x * Game.camera.zoom : handle_size * scale_x
      h_size_y = draw_relative_to_camera? ? handle_size * scale_y * Game.camera.zoom : handle_size * scale_y

      if orientation == Orientation::Horizontal
        hx = sx + (sw * norm) - (h_size_x / 2)
        hy = sy + (sh / 2) - (h_size_y / 2)
        FRect.new(x: hx.to_f32, y: hy.to_f32, w: h_size_x.to_f32, h: h_size_y.to_f32)
      else
        hx = sx + (sw / 2) - (h_size_x / 2)
        # top is max, bottom is min
        hy = sy + (sh * (1.0_f32 - norm)) - (h_size_y / 2)
        FRect.new(x: hx.to_f32, y: hy.to_f32, w: h_size_x.to_f32, h: h_size_y.to_f32)
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
      bg.draw_relative_to_camera = self.draw_relative_to_camera?
      bg.draw(draw)

      # Handle
      # Box.new(x, y) expects world coordinates if it's draw_relative_to_camera?
      # We calculate the center of the handle in world space.
      tl_x = x - (width * origin_x)
      tl_y = y - (height * origin_y)

      case orientation
      when Orientation::Horizontal
        hx_abs = tl_x + (width * normalized_value)
        hy_abs = tl_y + (height / 2.0_f32)
      else # Orientation::Vertical
        hx_abs = tl_x + (width / 2.0_f32)
        hy_abs = tl_y + (height * (1.0_f32 - normalized_value))
      end

      handle = Box.new(
        width: handle_size, height: handle_size,
        x: hx_abs.not_nil!, y: hy_abs.not_nil!,
        color: handle_color,
        origin: {0.5_f32, 0.5_f32},
        scale: scale,
        z_index: z_index + 1,
        border_radius: (handle_size / 2.0_f32).to_f32
      )
      handle.draw_relative_to_camera = self.draw_relative_to_camera?
      handle.draw(draw)
    end
  end
end
