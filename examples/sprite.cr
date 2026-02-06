require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "GSDL::TemplateManager Ex", width: WIDTH, height: HEIGHT)
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

      @sprite = GSDL::Sprite.new("player", 0, 0)
      @sprite.center(WIDTH, HEIGHT)
    end

    def update(frame_time)
    end

    def draw(renderer : SDL3::Renderer)
      @sprite.draw(renderer)
    end
  end

  Game.new.run
end
