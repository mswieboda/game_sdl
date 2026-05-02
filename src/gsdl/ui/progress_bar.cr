require "../gfx/geo/box"

module GSDL
  class ProgressBar
    include Tweenable

    enum Orientation
      Horizontal
      Vertical
    end

    property x : Num = 0
    property y : Num = 0
    property width : Num = 100
    property height : Num = 20
    property value : Num = 0.0_f32
    property background_color : Color = ColorScheme.get(:alt)
    property foreground_color : Color = ColorScheme.get(:success)
    property border_color : Color = ColorScheme.get(:border)
    property border_width : Num = 1
    property border_radius : Num = 0
    property z_index : Int32 = 0
    property orientation : Orientation = Orientation::Horizontal
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    property rotation : Num = 0
    property? draw_relative_to_camera : Bool = true

    getter tweens : Array(Tween) = [] of Tween

    def initialize(
      @x = 0, @y = 0, @width = 100, @height = 20,
      @value = 0.0_f32,
      @background_color = ColorScheme.get(:alt),
      @foreground_color = ColorScheme.get(:success),
      @border_color = ColorScheme.get(:border),
      @border_width = 1,
      @border_radius = 0,
      @orientation = Orientation::Horizontal,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @rotation = 0.0_f32,
      @z_index = 0
    )
    end

    def render_width : Num
      width * scale_x
    end

    def render_height : Num
      height * scale_y
    end

    def render_x : Num
      dx = x - (render_width * origin_x)
      draw_relative_to_camera? ? dx - Game.camera.x : dx
    end

    def render_y : Num
      dy = y - (render_height * origin_y)
      draw_relative_to_camera? ? dy - Game.camera.y : dy
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

    def update(dt : Float32)
      update_tweens(dt)
    end

    def draw(draw : GSDL::Draw)
      # Background
      bg = Box.new(
        width: width,
        height: height,
        x: x,
        y: y,
        color: background_color,
        origin: origin,
        scale: scale,
        rotation: rotation,
        z_index: z_index,
        border_radius: border_radius
      )
      bg.draw_relative_to_camera = self.draw_relative_to_camera?
      bg.draw(draw)

      # Foreground
      clamped_value = value.to_f32.clamp(0.0_f32, 1.0_f32)
      if clamped_value > 0
        fg_w = width
        fg_h = height
        fg_origin_x = origin_x
        fg_origin_y = origin_y

        if orientation == Orientation::Horizontal
          fg_w = width * clamped_value
          fg_origin_x = origin_x / clamped_value
        else
          fg_h = height * clamped_value
          fg_origin_y = 1.0_f32 - (1.0_f32 - origin_y) / clamped_value
        end

        fg = Box.new(
          width: fg_w,
          height: fg_h,
          x: x,
          y: y,
          color: foreground_color,
          origin: {fg_origin_x.to_f32, fg_origin_y.to_f32},
          scale: scale,
          rotation: rotation,
          z_index: z_index + 1,
          border_radius: border_radius
        )
        fg.draw_relative_to_camera = self.draw_relative_to_camera?
        fg.draw(draw)
      end

      # Border
      if border_width > 0
        border = Box.new(
          width: width,
          height: height,
          x: x,
          y: y,
          color: Color::Transparent,
          origin: origin,
          scale: scale,
          rotation: rotation,
          z_index: z_index + 2,
          draw_mode: Shape::DrawMode::Border,
          border_thickness: border_width,
          border_color: border_color,
          border_radius: border_radius
        )
        border.draw_relative_to_camera = self.draw_relative_to_camera?
        border.draw(draw)
      end
    end
  end
end
