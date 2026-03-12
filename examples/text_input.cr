require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Text Input Example", width: WIDTH, height: HEIGHT)
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

  class StartScene < GSDL::Scene
    @name_input : GSDL::TextInput
    @age_input : GSDL::TextInput
    @label_name : GSDL::Text
    @label_age : GSDL::Text
    @instructions : GSDL::Text

    def initialize
      super(:start)

      @instructions = GSDL::Text.new(
        text: "Click a box to type!",
        x: (WIDTH / 2).to_f32,
        y: 50,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White
      )

      @label_name = GSDL::Text.new(
        text: "Name:",
        x: 200,
        y: 200,
        origin: {1.0_f32, 0.5_f32},
        color: GSDL::Color::White
      )

      @name_input = GSDL::TextInput.new(
        text: "Player",
        x: 220,
        y: 200,
        origin: {0_f32, 0.5_f32},
        width: 300,
        height: 40,
        background_color: GSDL::Color.from_hex("#333333"),
        color: GSDL::Color::White,
        border_radius: 4,
        border_width: 2,
        border_color: GSDL::Color::White,
        max_length: 20
      )

      @label_age = GSDL::Text.new(
        text: "Age:",
        x: 200,
        y: 300,
        origin: {1.0_f32, 0.5_f32},
        color: GSDL::Color::White
      )

      @age_input = GSDL::TextInput.new(
        text: "25",
        x: 220,
        y: 300,
        origin: {0_f32, 0.5_f32},
        width: 100,
        height: 40,
        background_color: GSDL::Color.from_hex("#333333"),
        color: GSDL::Color::White,
        border_radius: 4,
        border_width: 2,
        border_color: GSDL::Color::White,
        max_length: 3
      )
    end

    def update(dt : Float32)
      @name_input.update(dt)
      @age_input.update(dt)

      if GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
        mx = GSDL::Mouse.x
        my = GSDL::Mouse.y

        # Basic hit detection
        if hit?(@name_input, mx, my)
          @name_input.active = true
          @age_input.active = false
          GSDL::Input.start_text_input
        elsif hit?(@age_input, mx, my)
          @name_input.active = false
          @age_input.active = true
          GSDL::Input.start_text_input
        else
          @name_input.active = false
          @age_input.active = false
          GSDL::Input.stop_text_input
        end
      end
    end

    private def hit?(input : GSDL::TextInput, x : GSDL::Num, y : GSDL::Num) : Bool
      # We need to calculate the bounding box
      # TextInput inherits from TextBox which has draw_x, draw_y, draw_width, draw_height
      x >= input.draw_x && x <= input.draw_x + input.draw_width &&
        y >= input.draw_y && y <= input.draw_y + input.draw_height
    end

    def draw(draw : GSDL::Draw)
      @instructions.draw(draw)
      @label_name.draw(draw)
      @name_input.draw(draw)
      @label_age.draw(draw)
      @age_input.draw(draw)
    end
  end

  Game.new.run
end
