require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Sprite Ex", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_fonts
      GSDL::FontManager.load_default("fonts/PressStart2P.ttf")
    end

    def load_textures
      GSDL::TextureManager.load("ship", "gfx/ship.png")
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super

      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @text : GSDL::Text
    @sprite : GSDL::Sprite

    def initialize
      super(:start)

      @text = GSDL::Text.new(text: "UP/DOWN to scale, TAB to tint", origin: {0.5_f32, 0.5_f32}, color: GSDL::Color::Lime)
      @text.x = WIDTH / 2_f32
      @text.y = @text.height + 32

      source_rect = GSDL::FRect.new(x: 0_f32, y: 0_f32, w: 128_f32, h: 128_f32)
      @sprite = GSDL::Sprite.new(key: "ship", origin: {0.5_f32, 0.5_f32}, source_rect: source_rect)

      @sprite.center(width: WIDTH, height: HEIGHT)
    end

    def update(dt : Float32)
      if Keys.just_pressed?([Keys::W, Keys::Up])
        @sprite.scale_x += 0.25_f32
        @sprite.scale_y += 0.25_f32
      elsif Keys.just_pressed?([Keys::S, Keys::Down])
        @sprite.scale_x -= 0.25_f32
        @sprite.scale_y -= 0.25_f32
      elsif Keys.just_pressed?(Keys::Tab)
        if tint = @sprite.tint
          @sprite.tint = nil
        else
          @sprite.tint = GSDL.color(r: 255, a: 128)
        end
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
      @sprite.draw(draw)
    end
  end

  Game.new.run
end
