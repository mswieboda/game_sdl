require "./text"

module GSDL
  class Notification
    include Tweenable

    property x : Num = 0
    property y : Num = 0
    property width : Num = 250
    property height : Num = 60
    property text : String = ""
    property color : Color = ColorScheme.get(:ui_text)
    property background_color : Color = GSDL.color(r: 30, g: 30, b: 30, a: 220)
    property lifetime : Float32 = 3.0_f32
    property elapsed : Float32 = 0.0_f32
    property z_index : Int32 = 2000

    # Internal state for the manager
    property? dead : Bool = false
    property target_y : Num = 0
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    getter tweens : Array(Tween) = [] of Tween

    def scale_x : Num; scale[0]; end
    def scale_y : Num; scale[1]; end

    def scale_x=(scale_x : Num)
      self.scale = {scale_x, scale_y}
    end

    def scale_y=(scale_y : Num)
      self.scale = {scale_x, scale_y}
    end

    @message : Text

    def initialize(
      @text = "",
      @lifetime = 3.0_f32,
      @background_color = GSDL.color(r: 30, g: 30, b: 30, a: 220),
      @color = ColorScheme.get(:ui_text),
      x = 0, y = 0,
      @z_index = 2000
    )
      @x = x.to_f32
      @y = y.to_f32
      @target_y = @y

      @message = Text.new(
        text: @text,
        color: @color,
        x: -1000, # make sure it's off the screen first
        y: -1000, # make sure it's off the screen first
        z_index: @z_index + 1,
        origin: {0.5_f32, 0.5_f32}
      )

      # Dynamic sizing with padding
      padding_x = 40
      padding_y = 30
      @width = @message.render_width + padding_x
      @height = @message.render_height + padding_y
    end

    def update(dt : Float32)
      update_tweens(dt)
      @elapsed += dt

      if @elapsed >= @lifetime && !@dead
        @dead = true
      end

      # Smoothly move towards target Y (for stacking)
      if @y != @target_y
        @y = MathUtils.lerp(@y.to_f32, @target_y.to_f32, 0.1_f32)
      end

      @message.x = (@x + width / 2).to_f32
      @message.y = (@y + height / 2).to_f32
      @message.update(dt)
    end

    def draw(draw : Draw)
      # Background box
      bg = Box.new(
        width: width, height: height,
        x: x, y: y,
        color: background_color,
        z_index: z_index,
        border_radius: 8,
        border_thickness: 2,
        border_color: color
      )
      bg.draw(draw)
      @message.draw(draw)
    end
  end

  module NotificationManager
    @@notifications = [] of Notification
    @@padding = 10
    @@margin_right = 20
    @@margin_top = 20

    def self.spawn(text : String, lifetime : Float32 = 3.0_f32, color : Color = ColorScheme.get(:ui_text))
      # Calculate initial off-screen x and target y
      screen_w = Game.width

      # We create it first to get its width
      n = Notification.new(text: text, lifetime: lifetime, color: color)

      # Now we can position it correctly
      target_x = screen_w - n.width - @@margin_right
      y = @@margin_top + (@@notifications.size * (n.height + @@padding))

      n.x = screen_w
      n.y = y
      n.target_y = y

      # Animate in
      n.tween({:x => target_x.to_f32}, 0.5_f32, MathUtils::Easing::EaseOut)
      @@notifications << n
      n
    end

    def self.update(dt : Float32)
      @@notifications.each(&.update(dt))

      # Remove dead ones
      old_size = @@notifications.size
      @@notifications.reject!(&.dead?)

      if @@notifications.size != old_size
        # Re-stack remaining notifications
        current_y = @@margin_top.to_f32
        @@notifications.each do |n|
          n.target_y = current_y
          current_y += n.height + @@padding
        end
      end
    end

    def self.draw(draw : Draw)
      @@notifications.each(&.draw(draw))
    end

    def self.clear
      @@notifications.clear
    end
  end
end
