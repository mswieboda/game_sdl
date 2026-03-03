require "./oval"

module GSDL
  class Circle < Oval
    def initialize(radius : Num = 16, rotation : Num = 0)
      super(radius_x: radius, radius_y: radius, rotation: rotation)
    end

    def initialize(
      x : Num = 0,
      y : Num = 0,
      origin = {0_f32, 0_f32},
      radius : Num = 16,
      scale = {1_f32, 1_f32},
      rotation : Num = 0,
      color : Color = Color::White,
      z_index : Int32 = 0,
      draw_mode : GSDL::Shape::DrawMode = GSDL::Shape::DrawMode::Fill,
      border_thickness : Num = 1,
      border_color : Color = Color::White
    )
      super(
        x: x,
        y: y,
        origin: origin,
        radius_x: radius,
        radius_y: radius,
        scale: scale,
        rotation: rotation,
        color: color,
        z_index: z_index,
        draw_mode: draw_mode,
        border_thickness: border_thickness,
        border_color: border_color
      )
    end

    # TODO: add setter
    def diameter
      radius * 2
    end

    def radius
      radius_x
    end

    def radius=(value : Num)
      return if radius == value
      @radius_x = value
      @radius_y = value
      @changed = true
    end
  end
end
