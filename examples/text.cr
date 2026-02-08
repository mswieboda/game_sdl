require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Text Example", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_fonts
      GSDL::FontManager.load(GSDL::Font::DEFAULT_FONT_PATH, GSDL::Font::DEFAULT_FONT_SIZE)
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
    @text : GSDL::Text

    def initialize
      super(:start)

      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)
      @text = GSDL::Text.new(text: "hello world!", color: color)

      # Center the text
      text_width = @text.width
      text_height = @text.height
      @text.center(WIDTH, HEIGHT)
    end

    def draw(renderer : GSDL::Renderer)
      @text.draw(renderer)
    end
  end

  Game.new.run
end
