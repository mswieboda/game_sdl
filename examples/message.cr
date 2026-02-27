require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Text Example", width: WIDTH, height: HEIGHT)
    end

    def init
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = StartScene.new
    end
  end

  class BorderedMessage < GSDL::Message
    def draw_border(draw : GSDL::Draw)
      return if border_radius > 0

      [2, 4, 6].each_with_index do |margin, i|
        box = GSDL::Box.new(
          x: x + margin,
          y: y + margin,
          width: (width - padding / 2).to_f32,
          height: (height - padding / 2).to_f32,
          color: @text.color,
          draw_mode: GSDL::Shape::DrawMode::Outline
        )
        box.draw(draw)
      end
    end
  end

  class StartScene < GSDL::Scene
    @messages : Array(GSDL::Message)
    @buttons : Array(GSDL::Button)

    def initialize
      super(:start)

      font = GSDL::Font.default.copy
      font.size = 12
      color = GSDL::Color::Red

      @messages = [] of GSDL::Message
      @buttons = [] of GSDL::Button

      @messages << GSDL::Message.new(
        font: font,
        text: "multiple lines\nof some text inside\na message box!",
        x: 64,
        y: 256,
        color: color,
        border_radius: 32
      )

      @messages << GSDL::Message.new(
        font: font,
        text: "multiple lines\nof some text inside\na message box!",
        x: 512,
        y: 320,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Magenta,
        border_radius: 32
      )

      margin = 16
      height = 36 + GSDL::TextBox::Padding * 2

      @messages << BorderedMessage.new(
        font: font,
        text: "automatically wrapped, with a set width. This could be a dialog box for character dialog, TBD a GSD::Dialog class to come later!",
        x: margin.to_f32,
        y: ((HEIGHT - height) - margin).to_f32,
        width: ((WIDTH - margin * 2).to_f32).to_i,
        height: height.to_i,
        color: color
      )

      @buttons << GSDL::Button.new(
        on_click: -> on_click(String),
        text: "OK!",
        x: 64.to_f32,
        y: 32.to_f32
      )
      @buttons << GSDL::Button.new(
        on_click: -> on_click(String),
        font: font,
        text: "OK! a large button",
        x: 512.to_f32,
        y: 128.to_f32,
        origin: {0.5_f32, 0.5_f32},
        scale: {2_f32, 3_f32},
        width: 128,
        color: color,
        border_radius: 16
      )
    end

    def on_click(text : String)
      puts ">>> on_click: text: #{text}"
    end

    def update(dt : Float32)
      @buttons.each(&.update(dt))
    end

    def draw(draw : GSDL::Draw)
      @messages.each(&.draw(draw))
      @buttons.each(&.draw(draw))
    end
  end

  Game.new.run
end
