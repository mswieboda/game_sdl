require "../src/game_sdl"

module NotificationsExample
  class Game < GSDL::Game
    def initialize
      super(title: "UI Notifications Example")
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MainScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class MainScene < GSDL::Scene
    @instructions : GSDL::Text

    def initialize
      super(:main)
      @instructions = GSDL::Text.new(
        text: "Press 1, 2, or 3 to spawn notifications",
        x: 400, y: 300,
        origin: {0.5_f32, 0.5_f32}
      )
    end

    def update(dt : Float32)
      @instructions.update(dt)
      GSDL::NotificationManager.update(dt)

      if GSDL::Keys.just_pressed?(GSDL::Keys::One)
        GSDL::NotificationManager.spawn("Item Found: Rusty Sword", color: GSDL::Color::White)
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Two)
        GSDL::NotificationManager.spawn("Level Up! You are now level 5", color: GSDL::Color::Gold)
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Three)
        GSDL::NotificationManager.spawn("Quest Started: The Goblin King", color: GSDL::Color::Cyan)
      end
    end

    def draw(draw : GSDL::Draw)
      @instructions.draw(draw)
      GSDL::NotificationManager.draw(draw)
    end
  end

  Game.new.run
end
