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
      GSDL::FontManager.load_default("fonts/PressStart2P.ttf")
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @message : GSDL::Message

    def initialize
      super(:start)

      font = GSDL::Font.default.copy
      font.size = 12
      color = GSDL::Colors::Red
      @message = GSDL::Message.new(
        font: font,
        text: "multiple lines of text inside a message box!",
        x: 64,
        y: 256,
        color: color
      )

      @button = GSDL::Button.new(
        font: font,
        text: "OK!",
        x: 128,
        y: 64,
        color: color
      )
    end

    def update(dt : Float32)
      @message.update(dt)
      @button.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @message.draw(draw)
      @button.draw(draw)
    end
  end

  Game.new.run
end
