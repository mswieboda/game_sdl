require "../src/game_sdl"

module GameEx
  class GameEx < GSDL::Game
    def initialize
      super(title: "Tint Baseline Test", width: 640, height: 480)
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(StartScene.new)
    end

    def load_textures
      [
        {"ship", "gfx/ship.png"},
        {"barrel", "gfx/barrel.png"}
      ]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class StartScene < GSDL::Scene
    @texture : GSDL::Texture?
    @barrel : GSDL::Texture?

    def initialize
      super(:start)
    end

    def init
      # Fetch the textures from the manager
      @texture = GSDL::TextureManager.get("ship")
      @barrel = GSDL::TextureManager.get("barrel")
    end

    def draw(draw : GSDL::Draw)
      return unless texture = @texture
      return unless barrel = @barrel

      # Command 1: Ship Tinted Red - DEFERRED
      draw.texture_rotated(
        texture: texture,
        x: 32_f32,
        y: 32_f32,
        tint: GSDL::Color.new(255, 0, 0, 128)
      )

      # Command 2: Barrel Tinted Blue - DEFERRED
      draw.texture_rotated(
        texture: barrel,
        x: 200_f32,
        y: 32_f32,
        tint: GSDL::Color.new(0, 0, 255, 128)
      )

      # Draw some text via GSDL::Draw just to confirm the system is alive
      draw.text(GSDL::Text.new(text: "Testing DEFERRED with 2 different textures (Red vs Blue)", x: 32, y: 200))
    end
  end

  GameEx.new.run
end
