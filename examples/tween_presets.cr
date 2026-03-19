require "../src/game_sdl"

# This example showcases the Tween presets in GSDL.
# Tweens can be used on any Tweenable object (Sprites, Shapes, etc.)
# to animate properties like x, y, scale, and color/tint over time.

module TweenPresetsEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Tween Presets Example", width: WIDTH, height: HEIGHT)
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
        text: "TAB toggles active object\n\n1: Flash   2: Pulse\n3: Spin    4: Shake",
        origin: text_origin,
        align: GSDL::Font::Align::Center,
        color: GSDL::Color::Lime
      )
      text.x = WIDTH / 2_f32
      text.y = 32

      text_rotated = GSDL::TextRotated.new(
        text: "ROTATED TEXT",
        origin: origin,
        color: GSDL::Color::Gold
      )
      text_rotated.x = WIDTH / 2_f32
      text_rotated.y = HEIGHT - 128

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
      line.center(width: WIDTH, height: HEIGHT)
      line.y += 96
      @objects << line

      @objects << GSDL::Pixel.new(
        x: WIDTH / 2_f32,
        y: HEIGHT / 2_f32 + 128
      )

      # add these last, so sprite is first, then shapes, then text
      @objects << text
      @objects << text_rotated
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

      if GSDL::Keys.just_pressed?(GSDL::Keys::One)
        active_object.tweens.clear
        active_object.flash
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Two)
        active_object.tweens.clear
        active_object.pulse
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Three)
        active_object.tweens.clear
        active_object.spin
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Four)
        active_object.tweens.clear
        active_object.shake
      end
    end

    def draw(draw : GSDL::Draw)
      @active_info.draw(draw)
      @objects.each(&.draw(draw))
    end
  end

  Game.new.run
end
