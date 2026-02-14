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
    @text : Array(GSDL::Text)

    def initialize
      super(:start)

      @text = [] of GSDL::Text

      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)
      @text << GSDL::Text.new(text: "hello world!", color: color)

      color = GSDL.color(r: 255, g: 160, b: 224)
      @text << GSDL::Text.new(text: "hello world!", color: color)

      color = GSDL.color(r: 255)
      @text << GSDL::TextTyped.new(text: "hello world!", color: color)

      color = GSDL.color_all(160)
      @text << GSDL::Text.new(text: "hello world!", color: color)

      color = GSDL::Colors::Indigo
      @text << GSDL::Text.new(text: "hello world!", color: color)

      color = GSDL::Colors.from_hex("#0000aa")
      @text << GSDL::TextTyped.new(text: "hello world!", color: color, chars_per_second: 12_u8)

      color = GSDL::Colors.random
      @text << GSDL::Text.new(text: "hello world!", color: color)

      color = GSDL::Colors.random_chunks(16)
      @text << GSDL::TextTyped.new(text: "hello world!", color: color, chars_per_second: 8_u8)
    end

    def update(dt : Float32)
      @text.each_with_index do |text, i|
        text.update(dt)

        # Center the text
        height_and_padding = text.height * 2
        centered_y_adjust = (@text.size * height_and_padding).to_f32
        text.center(WIDTH, HEIGHT - centered_y_adjust)
        text.y += i * height_and_padding
      end
    end

    def draw(draw : GSDL::Draw)
      @text.each(&.draw(draw))
    end
  end

  Game.new.run
end
