require "../src/game_sdl"

module PauseEx
  class Game < GSDL::Game
    def initialize
      super(title: "Pause Example", width: 800, height: 600)
    end

    def init
      GSDL::Events.esc_exits = false
      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = MainScene.new
    end
  end

  class MainScene < GSDL::Scene
    @text : GSDL::Text
    @rotation : Float32 = 0_f32

    def initialize
      super(:main)
      @text = GSDL::Text.new(
        text: "GAME RUNNING\n\nPress ENTER to Pause",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Lime,
        align: GSDL::Font::Align::Center
      )
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Return)
        GSDL::Game.instance.paused = true
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        GSDL::Game.instance.scene_manager.exit
      end

      @rotation += 100 * dt
      @text.scale = {1_f32 + Math.sin(@rotation * 0.05_f32) * 0.2_f32, 1_f32 + Math.sin(@rotation * 0.05_f32) * 0.2_f32}
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
