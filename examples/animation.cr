require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Animation Ex", width: WIDTH, height: HEIGHT)
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
    @sprite : GSDL::AnimatedSprite

    def initialize
      super(:start)

      @sprite = GSDL::AnimatedSprite.new("player", 128, 128)
      @sprite.center(WIDTH, HEIGHT)
      @sprite.add("fire", (0..3).to_a, 12)
      @sprite.play("fire")
    end

    def update(dt : Float32)
      @sprite.update(dt)
    end

    def draw(renderer : SDL3::Renderer)
      @sprite.draw(renderer)
    end
  end

  Game.new.run
end
