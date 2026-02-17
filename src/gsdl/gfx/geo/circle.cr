require "./oval"

module GSDL
  class Circle < Oval
    def initialize(radius : Num = 16)
      super(radius_x: radius, radius_y: radius)
    end

    def initialize(x, y, radius : Num = 16, color : Color = Color::White)
      super(x: x, y: y, radius_x: radius, radius_y: radius, color: color)
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

    def self.draw_filled(draw : Draw, circles : Array(Circle))
      draw.color = circles.first.color
      draw.filled(circles)
    end

    def self.draw_outlines(draw : Draw, circles : Array(Circle))
      draw.color = circles.first.color
      draw.outlines(circles)
    end

    def self.draw_outline(draw : Draw, circles : Array(Circle))
      draw_outlines(draw, circles)
    end
  end
end
