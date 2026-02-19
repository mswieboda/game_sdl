require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Sprite Ex", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_textures
      GSDL::TextureManager.load("ship", "gfx/ship.png")
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super

      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @sprites : Array(GSDL::Sprite) = [] of GSDL::Sprite

    def initialize
      super(:start)

      source_rect = GSDL::FRect.new(x: 0_f32, y: 0_f32, w: 128_f32, h: 128_f32)
      @sprites << GSDL::Sprite.new(key: "ship", origin: {0.5_f32, 0.5_f32}, source_rect: source_rect, tint: GSDL.color(r: 255, a: 128))

      @sprites.each(&.center(WIDTH, HEIGHT))
    end

    def draw(draw : GSDL::Draw)
      @sprites.each(&.draw(draw))
    end
  end

  Game.new.run
end
