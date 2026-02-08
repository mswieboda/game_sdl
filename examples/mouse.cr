require "../src/game_sdl"

module GameEx
  alias Mouse = GSDL::Mouse
  alias Font = GSDL::Font
  alias Text = GSDL::Text

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

    def load_fonts
      GSDL::FontManager.load(Font::DEFAULT_FONT_PATH, Font::DEFAULT_FONT_SIZE)
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
    @text : Text

    def initialize
      super(:start)
      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)
      @text = Text.new(text: "Move mouse or click buttons", color: color)
      @text.center(WIDTH, HEIGHT)
    end

    def update(dt : Float32)
      if Mouse.just_pressed?(Mouse::ButtonLeft)
        @text.text = "You just pressed Mouse Left!"
        @text.center(WIDTH, HEIGHT)
      end

      if Mouse.just_released?(Mouse::ButtonRight)
        @text.text = "You just released Mouse Right!"
        @text.center(WIDTH, HEIGHT)
      end

      if Mouse.moved?
        @text.text = "Mouse moved: #{Mouse.position}"
        @text.center(WIDTH, HEIGHT)
      end
    end

    def draw(renderer : GSDL::Renderer)
      @text.draw(renderer)
    end
  end

  Game.new.run
end
