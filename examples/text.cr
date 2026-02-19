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
    @text_wrapped : GSDL::Text

    def initialize
      super(:start)

      @text = [] of GSDL::Text

      color = GSDL.color(r: 255, g: 160, b: 224)
      @text << GSDL::Text.new(text: "hello world!", color: color)

      color = GSDL.color(r: 255)
      @text << GSDL::TextTyped.new(text: "word typed hello world!", color: color, types_per_second: 4_u8)

      color = GSDL.color_all(160)
      @text << GSDL::Text.new(text: "hello world!", color: color)

      color = GSDL::Color.from_hex("#0000aa")
      @text << GSDL::TextTyped.new(
        text: "char typed hello world!",
        color: color,
        type: GSDL::TextTyped::Type::Char, types_per_second: 16_u8
      )

      color = GSDL::Color.random_chunks(16)
      @text << GSDL::TextTyped.new(text: "hello world!", color: color, types_per_second: 8_u8)

      color = GSDL::Color::White
      @text << GSDL::TextTyped.new(
        text: "typed multiple lines\nof text\nwith newlines\naligned center",
        color: color,
        align: GSDL::Font::Align::Center
      )

      @text_wrapped = GSDL::TextTyped.new(
        text: "multiple lines\nof text\nwith newlines\nwrapped to a width too",
        color: color,
        wrap_width: 256
      )

      @text.each_with_index do |text, i|
        height_and_padding = text.height * 2
        centered_y_adjust = (@text.size * height_and_padding).to_f32
        text.center(WIDTH, HEIGHT - centered_y_adjust)
        text.y += i * height_and_padding
      end
    end

    def update(dt : Float32)
      @text.each_with_index do |text, i|
        text.update(dt)

        text.x = ((WIDTH - text.width) / 2).to_f32
      end
    end

    def draw(draw : GSDL::Draw)
      @text.each(&.draw(draw))
      @text_wrapped.draw(draw)
    end
  end

  Game.new.run
end
