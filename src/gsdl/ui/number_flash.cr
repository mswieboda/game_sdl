require "./text"

module GSDL
  class NumberFlash < Text
    property velocity : Point = Point.new(0, -100)
    property lifetime : Float32 = 1.0_f32
    property elapsed : Float32 = 0.0_f32

    def initialize(
      text : String,
      x : Num = 0,
      y : Num = 0,
      color = ColorScheme.get(:ui_text),
      font = Font.default,
      @velocity = Point.new(0, -100),
      @lifetime = 1.0_f32,
      z_index : Int32 = 100
    )
      super(
        font: font,
        text: text,
        x: x,
        y: y,
        color: color,
        origin: {0.5_f32, 0.5_f32},
        z_index: z_index
      )
    end

    def dead? : Bool
      @elapsed >= @lifetime
    end

    def update(dt : Float32)
      super(dt)
      @elapsed += dt

      # Move based on velocity
      self.x += velocity.x * dt
      self.y += velocity.y * dt

      # Fade out over lifetime
      progress = (@elapsed / @lifetime).clamp(0.0_f32, 1.0_f32)
      new_color = self.color
      new_color.a = (255 * (1.0_f32 - progress)).to_u8
      self.color = new_color
    end
  end
end
