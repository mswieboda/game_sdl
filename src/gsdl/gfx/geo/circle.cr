require "./oval"

module GSDL
  class Circle < Oval
    def initialize(radius : Num = 16)
      super(radius_x: radius, radius_y: radius)
    end

    def initialize(
      x : Num = 0,
      y : Num = 0,
      radius : Num = 16,
      color : Color = Color::White,
      draw_mode : Shape::DrawMode = Shape::DrawMode::Fill
    )
      super(x: x, y: y, radius_x: radius, radius_y: radius, color: color, draw_mode: draw_mode)
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
