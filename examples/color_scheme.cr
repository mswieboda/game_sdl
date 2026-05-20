require "../src/game_sdl"

# Example of how to override or setup a new ColorScheme for your game.
# You can do this at any point, but typically in your Game's initialize or init method.
GSDL::ColorScheme.configure(
  ui_text:    "#00FF00",                       # Green text (Hex)
  ui_bg:      "rgba(0, 0, 50, 200)",           # Dark blue semi-transparent (RGBA)
  main:       "rgb(255, 165, 0)",              # Orange (RGB)
  highlight:  GSDL::Color.new(r: 255, g: 0, b: 255), # Magenta (Color object)
  custom_key: "#FF5555",                      # New custom key
)

module ColorSchemeEx
  WIDTH  = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Color Scheme Example")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MainScene.new)
    end

    def load_default_font_old
      "fonts/PressStart2P.ttf"
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class MainScene < GSDL::Scene
    @text : GSDL::Text
    @button : GSDL::Button
    @progress : GSDL::ProgressBar
    @custom_text : GSDL::Text

    def initialize
      super(:main)

      # Uses ColorScheme.get(:ui_text) by default
      @text = GSDL::Text.new(
        text: "This text uses :ui_text (Green)",
        x: WIDTH // 2,
        y: 100,
        origin: {0.5_f32, 0.5_f32}
      )

      # Button uses :ui_text for text and :ui_bg for background
      @button = GSDL::Button.new(
        text: "Button (:ui_bg background)",
        x: WIDTH // 2,
        y: 200,
        width: 400,
        height: 60,
        origin: {0.5_f32, 0.5_f32}
      )

      # Progress bar uses :alt for background and :success for foreground by default
      # Let's override success just for this scene's example
      GSDL::ColorScheme.set(:success, "#5555FF") # Blue success

      @progress = GSDL::ProgressBar.new(
        x: WIDTH // 2,
        y: 300,
        width: 400,
        height: 30,
        value: 0.7_f32,
        origin: {0.5_f32, 0.5_f32}
      )

      # Using our custom key
      @custom_text = GSDL::Text.new(
        text: "This uses :custom_key (#FF5555)",
        x: WIDTH // 2,
        y: 400,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::ColorScheme.get(:custom_key)
      )
    end

    def update(dt : Float32)
      @text.update(dt)
      @button.update(dt)
      @progress.update(dt)
      @custom_text.update(dt)
    end

    def draw(draw : GSDL::Draw)
      # You can also use the scheme to clear the background
      draw.color = GSDL::ColorScheme.get(:ui_bg)
      draw.clear

      @text.draw(draw)
      @button.draw(draw)
      @progress.draw(draw)
      @custom_text.draw(draw)
    end
  end

  Game.new.run
end
