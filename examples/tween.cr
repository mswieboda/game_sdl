require "../src/game_sdl"

# This example showcases the Tween system in GSDL.
# Tweens can be used on any Tweenable object (Sprites, Shapes, etc.)
# to animate properties like x, y, scale, and color/tint over time.

module TweenEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Tweening Example")
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(TweenScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [{"ship", "gfx/ship.png"}]
    end
  end

  class TweenScene < GSDL::Scene
    @active_info : GSDL::Text
    @objects : Array(GSDL::Tweenable)
    @active_index = 0

    def initialize
      super(:tween)

      @objects = [] of GSDL::Tweenable

      text_origin = {0.5_f32, 0_f32}
      origin = {0.5_f32, 0.5_f32}

      text = GSDL::Text.new(
        text: "SPACE randomly tweens once\n\nS starts a complex tween looped\n\nTAB toggles sprite / shapes",
        origin: text_origin,
        align: GSDL::Font::Align::Center,
        color: GSDL::Color::Lime
      )
      text.x = WIDTH / 2_f32
      text.y = 32

      @active_info = GSDL::Text.new(
        text: "Active: Sprite",
        origin: text_origin,
        color: GSDL::Color::Yellow
      )
      @active_info.x = WIDTH / 2_f32
      @active_info.y = text.y + text.height + 16

      # Create a sprite to tween
      sprite = GSDL::Sprite.new(
        key: "ship",
        origin: origin,
        source_rect: GSDL::FRect.new(w: 128)
      )
      sprite.center(width: WIDTH, height: HEIGHT)
      @objects << sprite

      @objects << GSDL::Box.new(
        width: 100,
        height: 100,
        x: WIDTH / 4_f32,
        y: HEIGHT / 2_f32,
        color: GSDL::Color::Crimson,
        origin: origin,
        border_radius: 10
      )

      @objects << GSDL::Oval.new(
        x: (WIDTH * 3) / 4_f32,
        y: HEIGHT / 2_f32,
        radius_x: 64,
        radius_y: 96,
        color: GSDL::Color::Cyan,
        origin: origin
      )

      @objects << GSDL::Pie.new(
        x: (WIDTH * 3) / 4_f32,
        y: HEIGHT / 2_f32 + 128,
        radius: 96,
        color: GSDL::Color::Indigo,
        draw_mode: GSDL::Shape::DrawMode::Outline,
        origin: origin
      )

      triangle = GSDL::Triangle.new(
        x1: WIDTH / 2_f32 - 96,
        y1: HEIGHT / 2_f32,
        x2: WIDTH / 2_f32,
        y2: HEIGHT / 2_f32 + 32,
        x3: HEIGHT / 2_f32 + 32,
        y3: HEIGHT / 2_f32 + 64,
        color: GSDL::Color::White,
        origin: origin
      )
      triangle.center(width: WIDTH, height: HEIGHT)
      triangle.x -= 192
      triangle.y += 128
      @objects << triangle

      line = GSDL::Line.new(
        x1: WIDTH / 2_f32 - 96,
        y1: HEIGHT / 2_f32 + 96,
        x2: WIDTH / 2_f32 + 96,
        y2: HEIGHT / 2_f32 + 96,
      )
      line.origin = {0.5_f32, 0.5_f32}
      line.center(width: WIDTH, height: HEIGHT)
      line.y += 96
      @objects << line

      @objects << GSDL::Pixel.new(
        x: WIDTH / 2_f32,
        y: HEIGHT / 2_f32 + 128
      )

      # add these last, so sprite is first, then shapes, then text
      @objects << text
    end

    def active_object
      @objects[@active_index]
    end

    def update(dt : Float32)
      # Essential: call update on all objects so their tweens progress
      @objects.each(&.update(dt))

      if GSDL::Keys.just_pressed?(GSDL::Keys::Tab)
        @active_index = (@active_index + 1) % @objects.size
        name = active_object.class.name.split("::").last
        @active_info.text = "Active: #{name}"
      end

      # Trigger a simple one-step tween on the active object
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        obj = active_object
        obj.tweens.clear

        target_x = rand(100..WIDTH-100).to_f32
        target_y = rand(100..HEIGHT-150).to_f32
        target_scale = rand(0.5..2.0).to_f32

        obj.tween(
          to: {
            :x => target_x.as(GSDL::Tween::PropertyValue),
            :y => target_y.as(GSDL::Tween::PropertyValue),
            :scale => {target_scale, target_scale}.as(GSDL::Tween::PropertyValue)
          },
          duration: 1.0_f32,
          easing: GSDL::MathUtils::Easing::EaseInOut
        )
      end

      # Trigger a complex sequence on the active object
      if GSDL::Keys.just_pressed?(GSDL::Keys::S)
        obj = active_object
        obj.tweens.clear
        tween = obj.tween

        # Color property is called 'tint' for Sprites and 'color' for Shapes and Text
        color_prop = if obj.is_a?(GSDL::Sprite)
          :tint
        else
          :color
        end

        # Rotation property - added to the sequence for all objects that support it
        supports_rotation = obj.is_a?(GSDL::Sprite) || obj.is_a?(GSDL::Text) || obj.is_a?(GSDL::Shape)

        tween.add_sequence([
          {
            :duration => 0.8,
            :x        => WIDTH - 150.0,
            color_prop => GSDL::Color::Red,
            :rotation => supports_rotation ? 90.0 : 0.0,
            :easing   => :ease_in,
          },
          {
            :duration => 0.5,
            :y        => HEIGHT - 200.0,
            color_prop => GSDL::Color::Green,
            :scale    => 2.0,
            :rotation => supports_rotation ? 180.0 : 0.0,
            :easing   => :ease_out,
          },
          {
            :duration => 0.4,
            :scale    => 0.5,
            color_prop => GSDL::Color::Blue,
            :rotation => supports_rotation ? 270.0 : 0.0,
            :easing   => :ease_in_out,
          },
          {
            :duration => 1.0,
            :x        => WIDTH / 2.0,
            :y        => HEIGHT / 2.0,
            :scale    => 1.0,
            :rotation => supports_rotation ? 360.0 : 0.0,
            color_prop => GSDL::Color::White,
            :easing   => :linear,
          }
        ])

        tween.start(loop: true)
      end
    end

    def draw(draw : GSDL::Draw)
      @active_info.draw(draw)
      @objects.each(&.draw(draw))
    end
  end

  Game.new.run
end
