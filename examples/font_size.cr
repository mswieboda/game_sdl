require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def initialize
      super(title: "Font Management Example", width: 800, height: 640)
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
      @scene = FontScene.new
    end
  end

  class FontScene < GSDL::Scene
    @texts : Array(GSDL::Text)

    def initialize
      super(:font)
      @texts = [] of GSDL::Text

      x = Game.width / 2_f32
      origin = {0.5_f32, 0.5_f32}
      
      # Font 16 is default
      @texts << GSDL::Text.new(text: "Font size 16.0 (default)", y: 50, x: x, origin: origin)
      
      # Font size 24.0 (automatically loaded from base 'default')
      font24 = GSDL::Font.get("default", 24.0_f32)
      @texts << GSDL::Text.new(text: "Font size 24.0 (dynamic)", y: 150, x: x, font: font24, origin: origin)
      
      # Font size 32.0 (automatically loaded from base 'default')
      font32 = GSDL::Font.get("default", 32.0_f32)
      @texts << GSDL::Text.new(text: "Font size 32.0 (dynamic)", y: 250, x: x, font: font32, origin: origin)

      # Font size 48.0
      font48 = GSDL::Font.get("default", 48.0_f32)
      @texts << GSDL::Text.new(text: "Font size 48.0 (dynamic)", y: 400, x: x, font: font48, origin: origin)
    end

    def draw(draw : GSDL::Draw)
      @texts.each(&.draw(draw))
    end
  end

  Game.new.run
end
