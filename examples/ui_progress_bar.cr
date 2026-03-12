require "../src/game_sdl"

module UIExample
  class Game < GSDL::Game
    def initialize
      super(title: "UI Progress Bar Example", width: 800, height: 600)
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
      @scene = MainScene.new
    end
  end

  class MainScene < GSDL::Scene
    @health_bar : GSDL::ProgressBar
    @mana_bar : GSDL::ProgressBar
    @exp_bar : GSDL::ProgressBar
    @thick_border_bar : GSDL::ProgressBar
    @vertical_bar : GSDL::ProgressBar
    @rotated_bar : GSDL::ProgressBar
    @instructions : GSDL::Text
    @health_label : GSDL::Text
    @mana_label : GSDL::Text
    @exp_label : GSDL::Text
    @thick_border_label : GSDL::Text
    @flashes : Array(GSDL::NumberFlash) = [] of GSDL::NumberFlash

    def initialize
      super(:main)

      @instructions = GSDL::Text.new(
        text: "SPACE to animate bars | CLICK to spawn flashes",
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White,
        z_index: 10
      )
      @instructions.x = 400
      @instructions.y = 550

      @health_label = GSDL::Text.new(x: 50, y: 35, color: GSDL::Color::White)
      @mana_label = GSDL::Text.new(x: 50, y: 85, color: GSDL::Color::White)
      @exp_label = GSDL::Text.new(x: 50, y: 135, color: GSDL::Color::White)
      @thick_border_label = GSDL::Text.new(x: 50, y: 185, color: GSDL::Color::White, text: "Thick Border: 5px")

      @health_bar = GSDL::ProgressBar.new(
        x: 50, y: 50, width: 200, height: 30,
        value: 1.0,
        background_color: GSDL::Color::DarkRed,
        foreground_color: GSDL::Color::Red,
        border_color: GSDL::Color::White,
        border_width: 2,
        border_radius: 5
      )

      @mana_bar = GSDL::ProgressBar.new(
        x: 50, y: 100, width: 200, height: 20,
        value: 0.8,
        background_color: GSDL::Color::DarkBlue,
        foreground_color: GSDL::Color::Blue,
        border_radius: 10
      )

      @exp_bar = GSDL::ProgressBar.new(
        x: 50, y: 150, width: 200, height: 10,
        value: 0.0,
        background_color: GSDL::Color.new(50, 50, 50),
        foreground_color: GSDL::Color::Yellow,
        border_width: 0
      )

      @thick_border_bar = GSDL::ProgressBar.new(
        x: 50, y: 200, width: 200, height: 40,
        value: 0.6,
        background_color: GSDL::Color::DarkGray,
        foreground_color: GSDL::Color::Orange,
        border_color: GSDL::Color::White,
        border_width: 5,
        border_radius: 8
      )

      @vertical_bar = GSDL::ProgressBar.new(
        x: 300, y: 50, width: 30, height: 200,
        value: 0.5,
        orientation: GSDL::ProgressBar::Orientation::Vertical,
        background_color: GSDL::Color::DarkGray,
        foreground_color: GSDL::Color::Green,
        border_radius: 15
      )

      @rotated_bar = GSDL::ProgressBar.new(
        x: 500, y: 150, width: 150, height: 25,
        value: 0.75,
        rotation: 45,
        background_color: GSDL::Color::DarkGray,
        foreground_color: GSDL::Color::Purple,
        border_radius: 5,
        origin: {0.5_f32, 0.5_f32}
      )
    end

    def update(dt : Float32)
      @health_bar.update(dt)
      @mana_bar.update(dt)
      @exp_bar.update(dt)
      @thick_border_bar.update(dt)
      @vertical_bar.update(dt)
      @rotated_bar.update(dt)
      @instructions.update(dt)

      @health_label.text = "Health: #{(@health_bar.value.to_f32 * 100).to_i}%"
      @mana_label.text = "Mana: #{(@mana_bar.value.to_f32 * 100).to_i}%"
      @exp_label.text = "EXP: #{(@exp_bar.value.to_f32 * 100).to_i}%"

      @flashes.each(&.update(dt))
      @flashes.reject!(&.dead?)

      if GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
        # Spawn a damage-like flash
        val = rand(10..99)
        color = val > 80 ? GSDL::Color::Red : GSDL::Color::White
        @flashes << GSDL::NumberFlash.new(
          text: val.to_s,
          x: GSDL::Mouse.x,
          y: GSDL::Mouse.y,
          color: color,
          velocity: GSDL::Point.new(rand(-20..20), rand(-150..-100)),
          lifetime: 0.75_f32
        )
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        # Test tweening
        new_health = (@health_bar.value.to_f32 > 0.5_f32 ? 0.2_f32 : 1.0_f32)
        @health_bar.tween({"value" => new_health}, 1.0_f32, GSDL::MathUtils::Easing::EaseInOut)

        @exp_bar.value = 0.0_f32
        @exp_bar.tween({"value" => 1.0_f32}, 2.0_f32, GSDL::MathUtils::Easing::Linear)

        new_thick = (@thick_border_bar.value.to_f32 > 0.5_f32 ? 0.3_f32 : 0.8_f32)
        @thick_border_bar.tween({"value" => new_thick}, 1.5_f32, GSDL::MathUtils::Easing::EaseInOut)
        
        new_vert = (@vertical_bar.value.to_f32 > 0.5_f32 ? 0.1_f32 : 0.9_f32)
        @vertical_bar.tween({"value" => new_vert}, 0.5_f32, GSDL::MathUtils::Easing::EaseOut)

        @rotated_bar.tween({"rotation" => @rotated_bar.rotation.to_f32 + 360.0_f32}, 2.0_f32, GSDL::MathUtils::Easing::EaseInOut)
      end
    end

    def draw(draw : GSDL::Draw)
      @health_bar.draw(draw)
      @mana_bar.draw(draw)
      @exp_bar.draw(draw)
      @thick_border_bar.draw(draw)
      @vertical_bar.draw(draw)
      @rotated_bar.draw(draw)
      @instructions.draw(draw)
      @health_label.draw(draw)
      @mana_label.draw(draw)
      @exp_label.draw(draw)
      @thick_border_label.draw(draw)
      @flashes.each(&.draw(draw))
    end
  end

  Game.new.run
end
