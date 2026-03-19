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
      GSDL::Events.esc_exits = true
      GSDL::Game.push(StartScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class StartScene < GSDL::Scene
    @text : Text

    def initialize
      super(:start)
      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)
      @text = Text.new(
        text: "Move mouse or click buttons",
        origin: {0.5_f32, 0.5_f32},
        color: color
      )
      @text.center(width: WIDTH, height: HEIGHT)
    end

    def update(dt : Float32)
      if Mouse.just_pressed?(Mouse::ButtonLeft)
        @text.text = "You just pressed Mouse Left!"
      end

      if Mouse.just_released?(Mouse::ButtonRight)
        @text.text = "You just released Mouse Right!"
      end

      if Mouse.moved?
        @text.text = "Mouse moved: #{Mouse.position}"
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
