require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Keys Ex", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_textures
      GSDL::TextureManager.load("player", "./assets/gfx/player.png")
    end
  end

  class SceneManager < GSDL::SceneManager
    getter start

    def initialize
      super

      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @sprite : GSDL::Sprite

    def initialize
      super(:start)

      source_rect = SDL3::FRect.new(x: 0_f32, y: 0_f32, w: 128_f32, h: 128_f32)
      @sprite = GSDL::Sprite.new(key: "player", source_rect: source_rect)
      @sprite.center(WIDTH, HEIGHT)
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
        puts ">>> You just pressed RETURN!"
      end

      if Keys.just_released?(Keys::Space)
        puts ">>> You just released SPACE!"
      end
    end

    def draw(renderer : GSDL::Renderer)
      @sprite.draw(renderer)
    end
  end

  Game.new.run
end
