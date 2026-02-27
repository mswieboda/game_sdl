require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias Font = GSDL::Font
  alias Text = GSDL::Text

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Keys Ex", width: WIDTH, height: HEIGHT)
    end

    def init
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [{"ship", "gfx/ship.png"},]
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super

      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @sprite : GSDL::Sprite
    @text : Text

    def initialize
      super(:start)

      @sprite = GSDL::Sprite.new(
        key: "ship",
        origin: {0.5_f32, 0.5_f32},
        source_rect: GSDL::FRect.new(w: 128)
      )
      @sprite.center(width: WIDTH, height: HEIGHT)

      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)
      @text = Text.new(text: "Use WASD or Arrows to move", color: color)
      center_text
      @text.y = @sprite.y + @sprite.height + 20 # Position below sprite
    end

    def center_text
      @text.x = ((WIDTH - @text.width) / 2).to_f32
    end

    def update(dt : Float32)
      speed = 150 * dt
      if Keys.pressed?([Keys::A, Keys::Left])
        @sprite.x -= speed
      end
      if Keys.pressed?([Keys::D, Keys::Right])
        @sprite.x += speed
      end
      if Keys.pressed?([Keys::W, Keys::Up])
        @sprite.y -= speed
      end
      if Keys.pressed?([Keys::S, Keys::Down])
        @sprite.y += speed
      end

      if Keys.just_pressed?(Keys::Return)
        @text.text = "You just pressed RETURN!"
        center_text
      end

      if Keys.just_released?(Keys::Space)
        @text.text = "You just released SPACE!"
        center_text
      end
    end

    def draw(draw : GSDL::Draw)
      @sprite.draw(draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
