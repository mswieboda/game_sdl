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
    @sprite : GSDL::Sprite

    def initialize
      super(:tween)

      @text = GSDL::Text.new(
        text: "SPACE randomly tweens once\n\nS starts a complex tween looped",
        origin: {0.5_f32, 0.5_f32},
        align: GSDL::Font::Align::Center,
        color: GSDL::Color::Lime
      )
      @text.x = WIDTH / 2_f32
      @text.y = 32

      # Create a sprite to tween
      source_rect = GSDL::FRect.new(x: 0_f32, y: 0_f32, w: 128_f32, h: 128_f32)
      @sprite = GSDL::Sprite.new(
        key: "ship", 
        origin: {0.5_f32, 0.5_f32},
        source_rect: source_rect
      )
      @sprite.center(WIDTH, HEIGHT)
    end

    def update(dt : Float32)
      # Essential: call update on the sprite so its tweens progress
      @sprite.update(dt)

      # Trigger a simple one-step tween
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        # Clear existing tweens if you want to override
        @sprite.tweens.clear
        
        # Move to a random position and scale up/down with EaseInOut
        target_x = rand(100..WIDTH-100).to_f32
        target_y = rand(100..HEIGHT-150).to_f32
        target_scale = rand(0.5..2.5).to_f32

        @sprite.tween(
          to: {
            "x" => target_x.as(GSDL::Tween::PropertyValue),
            "y" => target_y.as(GSDL::Tween::PropertyValue),
            "scale" => {target_scale, target_scale}.as(GSDL::Tween::PropertyValue)
          },
          duration: 1.0_f32,
          easing: GSDL::Tween::Easing::EaseInOut
        )
      end

      # Trigger a complex sequence
      if GSDL::Keys.just_pressed?(GSDL::Keys::S)
        @sprite.tweens.clear
        @sprite.center(WIDTH, HEIGHT)
        
        # Define a sequence of movements and style changes
        # The tween system handles the interpolation between these steps
        tween = @sprite.tween
        tween.add_sequence([
          # Move right and turn red
          { 
            "duration" => 0.8, 
            "x" => WIDTH - 150.0, 
            "tint" => GSDL::Color::Red,
            "easing" => "ease_in" 
          },
          # Move down and turn green while scaling up
          { 
            "duration" => 0.5, 
            "y" => HEIGHT - 200.0, 
            "tint" => GSDL::Color::Green,
            "scale" => 2.0,
            "easing" => :ease_out
          },
          # Scale down and turn blue
          { 
            "duration" => 0.4, 
            "scale" => 0.5, 
            "tint" => GSDL::Color::Blue,
            "easing" => "ease_in_out"
          },
          # Return to center and original state
          { 
            "duration" => 1.0, 
            "x" => WIDTH / 2.0, 
            "y" => HEIGHT / 2.0, 
            "scale" => 1.0,
            "tint" => GSDL::Color::White,
            "easing" => :linear
          }
        ])

         # Start the sequence and loop it
        tween.start(loop: true)
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
      @sprite.draw(draw)
    end
  end

  Game.new.run
end
