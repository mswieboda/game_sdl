module GSDL
  class ProjectionMatrix
    property x : Float32 = 0_f32
    property y : Float32 = 0_f32
    property width : Float32 = 0_f32
    property height : Float32 = 0_f32
    property zoom_x : Float32 = 1.0_f32
    property zoom_y : Float32 = 1.0_f32

    def initialize(@x = 0_f32, @y = 0_f32, @width = 0_f32, @height = 0_f32, @zoom_x = 1.0_f32, @zoom_y = 1.0_f32)
    end

    def zoom=(val : Num)
      @zoom_x = val.to_f32
      @zoom_y = val.to_f32
    end

    def zoom
      @zoom_x
    end

    def self.identity
      new
    end

    def self.from_game
      new(width: Game.width.to_f32, height: Game.height.to_f32)
    end

    def center_on(tx : Num, ty : Num)
      @x = tx.to_f32 - (@width / (2_f32 * @zoom_x))
      @y = ty.to_f32 - (@height / (2_f32 * @zoom_y))
    end

    def viewport_rect : FRect
      FRect.new(x: @x, y: @y, w: @width / @zoom_x, h: @height / @zoom_y)
    end
  end
end
