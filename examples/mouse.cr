require "../src/game_sdl"

module GameEx
  alias Mouse = GSDL::Mouse

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Mouse Ex", width: WIDTH, height: HEIGHT)
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
    def update(dt : Float32)
      if Mouse.just_pressed?(Mouse::ButtonLeft)
        puts ">>> You just pressed Mouse Left!"
      end

      if Mouse.just_released?(Mouse::ButtonRight)
        puts ">>> You just released Mouse Right!"
      end

      if Mouse.moved?
        puts ">>> Mouse moved: #{Mouse.position}"
      end
    end
  end

  Game.new.run
end
