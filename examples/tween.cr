require "../src/game_sdl"

# This example showcases the Tween system in GSDL.
# Tweens can be used on any Tweenable object (Sprites, Shapes, etc.)
# to animate properties like x, y, scale, and color/tint over time.

module TweenEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Tweening Example", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_fonts
      GSDL::FontManager.load_default("fonts/PressStart2P.ttf")
    end

    def load_textures
      GSDL::TextureManager.load("ship", "gfx/ship.png")
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = TweenScene.new
    end
  end

  class TweenScene < GSDL::Scene
    @text : GSDL::Text
    @active_info : GSDL::Text
    @sprite : GSDL::Sprite
    @box : GSDL::Box
    @circle : GSDL::Circle
    @text_rotated : GSDL::TextRotated
    @objects : Array(GSDL::Tweenable)
    @active_index = 0

    def initialize
      super(:tween)

      @text = GSDL::Text.new(
        text: "SPACE randomly tweens once\n\nS starts a complex tween looped\n\nTAB toggles sprite / shapes",
        origin: {0.5_f32, 0_f32},
        align: GSDL::Font::Align::Center,
        color: GSDL::Color::Lime
      )
      @text.x = WIDTH / 2_f32
      @text.y = 32

      @text_rotated = GSDL::TextRotated.new(
        text: "ROTATED TEXT",
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Gold
      )
      @text_rotated.x = WIDTH / 2_f32
      @text_rotated.y = HEIGHT - 128

      @active_info = GSDL::Text.new(
        text: "Active: Sprite",
        origin: {0.5_f32, 0_f32},
        color: GSDL::Color::Yellow
      )
      @active_info.x = WIDTH / 2_f32
      @active_info.y = @text.y + @text.height + 16

      # Create a sprite to tween
      source_rect = GSDL::FRect.new(x: 0_f32, y: 0_f32, w: 128_f32, h: 128_f32)
      @sprite = GSDL::Sprite.new(
        key: "ship",
        origin: {0.5_f32, 0.5_f32},
        source_rect: source_rect
      )
      @sprite.center(WIDTH, HEIGHT)

      @box = GSDL::Box.new(
        width: 100,
        height: 100,
        x: WIDTH / 4_f32,
        y: HEIGHT / 2_f32,
        color: GSDL::Color::Crimson,
        origin: {0.5_f32, 0.5_f32},
        border_radius: 10
      )

      @circle = GSDL::Circle.new(
        x: (WIDTH * 3) / 4_f32,
        y: HEIGHT / 2_f32,
        radius: 50,
        color: GSDL::Color::Cyan,
        origin: {0.5_f32, 0.5_f32}
      )

      @objects = [@sprite, @box, @circle, @text, @text_rotated] of GSDL::Tweenable
    end

    def active_object
      @objects[@active_index]
    end

    def update(dt : Float32)
      # Essential: call update on all objects so their tweens progress
      @objects.each(&.update(dt))

      if GSDL::Keys.just_pressed?(GSDL::Keys::Tab)
        @active_index = (@active_index + 1) % @objects.size
        name = case active_object
               when GSDL::Sprite      then "Sprite"
               when GSDL::Box         then "Box"
               when GSDL::Circle      then "Circle"
               when GSDL::TextRotated then "Text Rotated"
               when GSDL::Text        then "Text"
               else                        "Unknown"
               end
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
            "x" => target_x.as(GSDL::Tween::PropertyValue),
            "y" => target_y.as(GSDL::Tween::PropertyValue),
            "scale" => {target_scale, target_scale}.as(GSDL::Tween::PropertyValue)
          },
          duration: 1.0_f32,
          easing: GSDL::Tween::Easing::EaseInOut
        )
      end

      # Trigger a complex sequence on the active object
      if GSDL::Keys.just_pressed?(GSDL::Keys::S)
        obj = active_object
        obj.tweens.clear
        tween = obj.tween

        # Color property is called 'tint' for Sprites and 'color' for Shapes and Text
        color_prop = if obj.is_a?(GSDL::Sprite)
          "tint"
        else
          "color"
        end

        # Rotation property - added to the sequence only for Sprites and TextRotated
        supports_rotation = obj.is_a?(GSDL::Sprite) || obj.is_a?(GSDL::TextRotated)

        tween.add_sequence([
          {
            "duration" => 0.8,
            "x" => WIDTH - 150.0,
            color_prop => GSDL::Color::Red,
            "rotation" => supports_rotation ? 90.0 : 0.0,
            "easing" => "ease_in"
          },
          {
            "duration" => 0.5,
            "y" => HEIGHT - 200.0,
            color_prop => GSDL::Color::Green,
            "scale" => 2.0,
            "rotation" => supports_rotation ? 180.0 : 0.0,
            "easing" => :ease_out
          },
          {
            "duration" => 0.4,
            "scale" => 0.5,
            color_prop => GSDL::Color::Blue,
            "rotation" => supports_rotation ? 270.0 : 0.0,
            "easing" => "ease_in_out"
          },
          {
            "duration" => 1.0,
            "x" => WIDTH / 2.0,
            "y" => HEIGHT / 2.0,
            "scale" => 1.0,
            "rotation" => supports_rotation ? 360.0 : 0.0,
            color_prop => GSDL::Color::White,
            "easing" => :linear
          }
        ])

        tween.start(loop: true)
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
      @active_info.draw(draw)
      @objects.each(&.draw(draw))
    end
  end

  Game.new.run
end
