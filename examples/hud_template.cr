require "../src/game_sdl"

module HUDTemplateEx
  class Game < GSDL::Game
    def initialize
      super(title: "HUD Template Example")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MainScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_fonts
      [{"fonts/PressStart2P.ttf", 12, 0}]
    end
  end

  class MainScene < GSDL::Scene
    def initialize
      super(:main)

      GSDL::Data.set("score", 0)
      GSDL::Data.set("health", 100)
      GSDL::Data.set("status", "Exploring")

      @text = GSDL::Text.new(
        text: "blah\nfoo bar\nbaz andallthat",
        x: Game.width // 2,
        y: 300,
        origin: {0.5_f32, 0.5_f32},
        h_align: GSDL::HorizontalAlign::Center
      )

      h = GSDL::HUD.new

      # Combined template: Score and Health in one HUDText
      h << GSDL::HUDText.new(
        text_data_template: "Score: {score}\nHealth: {health}%",
        anchor: GSDL::Anchor::TopLeft,
        offset_x: 8,
        offset_y: 8,
        color: GSDL::Color::Yellow
      )

      # Another template for status
      h << GSDL::HUDText.new(
        text_data_template: "Status:\n[{status}]",
        anchor: GSDL::Anchor::TopCenter,
        offset_y: 8,
        origin: {0.5_f32, 0.0_f32},
        color: GSDL::Color::White,
        h_align: GSDL::HorizontalAlign::Center
      )

      # Template with calculation/prefix/suffix
      h << GSDL::HUDText.new(
        text_data_template: "LIVES: {lives}\nKILLS: 10",
        anchor: GSDL::Anchor::TopRight,
        offset_x: 8,
        offset_y: 8,
        origin: {1.0_f32, 0.0_f32},
        color: GSDL::Color::Red,
        h_align: GSDL::HorizontalAlign::Right
      )
      GSDL::Data.set("lives", 3)

      # Instructions
      h << GSDL::HUDText.new(
        font_size: 12,
        text: "SPACE: Increase Score | H: Decrease Health | S: Change Status",
        anchor: GSDL::Anchor::BottomCenter,
        offset_y: 32,
        origin: {0.5_f32, 1.0_f32},
        color: GSDL::Color::White,
        # scale: 0.75_f32
      )

      self.hud = h
    end

    def draw(draw : GSDL::Draw)
      super(draw)
      @text.draw(draw)
    end

    def update(dt : Float32)
      super(dt)

      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        GSDL::Data.increment("score", 100)
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::H)
        health = GSDL::Data.get("health").as_i - 10
        health = 0 if health < 0
        GSDL::Data.set("health", health)
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::S)
        statuses = ["Exploring", "Fighting", "Resting", "Level Up!"]
        current = GSDL::Data.get("status").as_s
        idx = statuses.index(current) || 0
        GSDL::Data.set("status", statuses[(idx + 1) % statuses.size])
      end
    end
  end

  Game.new.run
end
