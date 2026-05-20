require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def initialize
      super(title: "Font Management Example")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(FontScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_fonts
      [
        {"fonts/PressStart2P.ttf", 24, 0},
        {"fonts/PressStart2P.ttf", 32, 0},
        {"fonts/PressStart2P.ttf", 48, 0},
      ]
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
      @texts << GSDL::Text.new(text: "Font size 16 (default)", y: 50, x: x, origin: origin)

      # Font size 24
      @texts << GSDL::Text.new(font_size: 24, text: "Font size 24", y: 150, x: x, origin: origin)

      # Font size 32
      @texts << GSDL::Text.new(font_size: 32, text: "Font size 32", y: 250, x: x, origin: origin)

      # Font size 48
      @texts << GSDL::Text.new(font_size: 48, text: "Font size 48", y: 400, x: x, origin: origin)
    end

    def draw(draw : GSDL::Draw)
      @texts.each(&.draw(draw))
    end
  end

  Game.new.run
end
