require "../src/game_sdl"

module HUDEx
  class Game < GSDL::Game
    def initialize
      super(title: "HUD Example", width: 800, height: 600)
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(StartScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class StartScene < GSDL::Scene
    @camera : GSDL::Camera
    @player_x : Float32 = 400_f32
    @player_y : Float32 = 300_f32

    def initialize
      super(:start)

      GSDL::Data.set("score", 0)
      GSDL::Data.set("health", 1.0_f32)
      GSDL::Data.set("status", "Active")

      @camera = GSDL::Camera.new(800, 600)

      h = GSDL::HUD.new

      # Top Left: Score (Data Bound)
      h << GSDL::HUDText.new(
        text: "Score: 0",
        data_key: "score",
        anchor: GSDL::Anchor::TopLeft,
        offset_x: 20,
        offset_y: 20,
        color: GSDL::Color::Yellow
      )

      # Top Center: Status (Data Bound)
      h << GSDL::HUDText.new(
        text: "Active",
        data_key: "status",
        anchor: GSDL::Anchor::TopCenter,
        offset_y: 20,
        origin: {0.5_f32, 0.0_f32},
        color: GSDL::Color::Cyan
      )

      # Top Right: Health Bar (Data Bound)
      h << GSDL::HUDProgressBar.new(
        data_key: "health",
        anchor: GSDL::Anchor::TopRight,
        offset_x: 20,
        offset_y: 20,
        width: 150,
        height: 20,
        foreground_color: GSDL::Color::Red,
        origin: {1.0_f32, 0.0_f32}
      )

      # Bottom Center: Instructions
      h << GSDL::HUDText.new(
        text: "WASD: Move | SPACE: Score | H: Drain Health | R: Refill",
        anchor: GSDL::Anchor::BottomCenter,
        offset_y: 20,
        origin: {0.5_f32, 1.0_f32},
        color: GSDL::Color::White,
        scale: 0.75_f32
      )

      self.hud = h
    end

    def update(dt : Float32)
      super(dt)

      # Player movement
      speed = 300_f32
      @player_x -= speed * dt if GSDL::Keys.pressed?(GSDL::Keys::A)
      @player_x += speed * dt if GSDL::Keys.pressed?(GSDL::Keys::D)
      @player_y -= speed * dt if GSDL::Keys.pressed?(GSDL::Keys::W)
      @player_y += speed * dt if GSDL::Keys.pressed?(GSDL::Keys::S)

      @camera.look_at(@player_x, @player_y)
      @camera.update(dt)

      # Data binding tests
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        GSDL::Data.increment("score", 100)
      end

      if GSDL::Keys.pressed?(GSDL::Keys::H)
        health = GSDL::Data.get("health").as_f - 0.5 * dt
        health = 0.0 if health < 0.0
        GSDL::Data.set("health", health)
        GSDL::Data.set("status", "Draining...")
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::R)
        GSDL::Data.set("health", 1.0)
        GSDL::Data.set("status", "Active")
      end
    end

    def draw(draw : GSDL::Draw)
      # Draw world with camera transform
      draw_world(draw)

      # Draw HUD (camera NOT applied, it's screen space)
      super(draw)
    end

    def draw_world(draw : GSDL::Draw)
      grid_size = 64
      cam_x = @camera.x
      cam_y = @camera.y

      (0..30).each do |i|
        x = i * grid_size
        draw.line(x - cam_x, 0 - cam_y, x - cam_x, 2000 - cam_y, GSDL::Color::DarkerGray)
      end
      (0..30).each do |i|
        y = i * grid_size
        draw.line(0 - cam_x, y - cam_y, 2000 - cam_x, y - cam_y, GSDL::Color::DarkerGray)
      end

      # Draw player
      draw.rect_fill(
        rect: GSDL::FRect.new(x: @player_x - cam_x - 16, y: @player_y - cam_y - 16, w: 32, h: 32),
        color: GSDL::Color::Lime
      )
    end
  end

  Game.new.run
end
