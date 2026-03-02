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
    @messages : Array(GSDL::Message | GSDL::MessageRotated)
    @buttons : Array(GSDL::Button | GSDL::ButtonRotated)

    def initialize
      super(:start)

      font = GSDL::Font.default.copy
      font.size = 12
      color = GSDL::Color::Red

      @messages = [] of GSDL::Message | GSDL::MessageRotated
      @buttons = [] of GSDL::Button | GSDL::ButtonRotated

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

      @messages << GSDL::MessageTyped.new(
        font: font,
        text: "typing out some\nwords slowly!",
        x: 64,
        y: 400,
        color: GSDL::Color::Blue,
        border_radius: 32,
        types_per_second: 5_u8,
        type: GSDL::TextTyped::Type::Word
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

      @messages << GSDL::MessageRotated.new(
        font: font,
        text: "Rotated\nmessage\nwow!",
        x: 400.to_f32,
        y: 400.to_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Green,
        border_radius: 16,
        rotation: 15.0_f32
      )

      @buttons << GSDL::ButtonRotated.new(
        on_click: -> on_click(String),
        text: "Rotated OK!",
        x: 600.to_f32,
        y: 450.to_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Cyan,
        border_radius: 16,
        rotation: -25.0_f32
      )
    end

    def on_click(text : String)
      puts ">>> on_click: text: #{text}"
    end

    def update(dt : Float32)
      @messages.each(&.update(dt))
      @buttons.each(&.update(dt))
    end

    def draw(draw : GSDL::Draw)
      @messages.each(&.draw(draw))
      @buttons.each(&.draw(draw))
    end
  end

  Game.new.run
end
