require "../src/game_sdl"

module GameEx
  alias Mouse = GSDL::Mouse
  alias Text = GSDL::Text

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Mouse Visibility Ex", width: WIDTH, height: HEIGHT)
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
      @scene = VisibilityScene.new
    end
  end

  class VisibilityScene < GSDL::Scene
    @text : Text

    def initialize
      super(:visibility)
      color = GSDL::Color.new(r: 255, g: 255, b: 255, a: 255)
      @text = Text.new(
        text: "Press 'H' to Hide, 'S' to Show, 'T' to Toggle",
        origin: {0.5_f32, 0.5_f32},
        color: color
      )
      @text.center(width: WIDTH, height: HEIGHT)
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::H)
        Mouse.hide
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::S)
        Mouse.show
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::T)
        Mouse.visible = !Mouse.visible?
      end

      visibility_str = Mouse.visible? ? "Visible" : "Hidden"
      @text.text = "Mouse is: #{visibility_str}. H: Hide, S: Show, T: Toggle"
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
