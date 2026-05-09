require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys

  class GameEx < GSDL::Game
    def initialize
      super(title: "Sprite Ex", width: 800, height: 600)
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(StartScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [{"ship", "gfx/ship.png"}]
    end
  end

  class StartScene < GSDL::Scene
    @text : GSDL::Text
    @sprite : GSDL::Sprite

    def initialize
      super(:start)

      @text = GSDL::Text.new(text: "UP/DOWN to scale, TAB to tint", origin: {0.5_f32, 0.5_f32}, color: GSDL::Color::Lime)

      # NOTE: can use either GSDL::Game.width or GameEx.width
      @text.x = GSDL::Game.width / 2_f32
      @text.y = @text.height + 32

      @sprite = GSDL::Sprite.new(
        key: "ship",
        origin: {0.5_f32, 0.5_f32},
        source_rect: GSDL::FRect.new(w: 128_f32)
      )

      # NOTE: can use either GSDL::Game.width or GameEx.width
      @sprite.center(width: GameEx.width, height: GameEx.height)
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

    def draw_camera_view(draw : GSDL::Draw)
      @text.draw(draw)
      @sprite.draw(draw)
    end
  end

  GameEx.new.run
end
