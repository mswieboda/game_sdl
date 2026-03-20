require "../src/game_sdl"

module BenchmarkEx
  WORLD_SIZE = 2000
  SHIP_SIZE = 128_f32

  class Game < GSDL::Game
    def initialize
      super(title: "Collision Benchmark", width: 800, height: 600)
      self.target_fps = 60
    end

    def init
      GSDL::Events.esc_exits = true
      # Enable performance monitoring
      self.performance_monitoring_enabled = true
      GSDL::Game.push(BenchmarkScene.new)
    end

    def load_textures
      [{"ship", "gfx/ship.png"}]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class Wall < GSDL::Sprite
    def initialize(x, y, w, h)
      # Using ship as a placeholder texture for walls
      # Ship frames are 128x128
      super(
        key: "ship",
        x: x,
        y: y,
        scale: {(w / SHIP_SIZE).to_f32, (h / SHIP_SIZE).to_f32},
        source_rect: GSDL::FRect.new(0, 0, SHIP_SIZE, SHIP_SIZE)
      )
      self.tint = GSDL::Color::DarkGray
    end
  end

  class Mover < GSDL::Sprite
    include GSDL::MoveController
    def initialize(x, y)
      super(
        key: "ship",
        x: x,
        y: y,
        origin: {0.5_f32, 0.5_f32},
        scale: {0.5_f32, 0.5_f32},
        source_rect: GSDL::FRect.new(0, 0, SHIP_SIZE, SHIP_SIZE)
      )
      self.dx = (Random.rand * 2 - 1).to_f32
      self.dy = (Random.rand * 2 - 1).to_f32
    end

    def move_speed : GSDL::Num; 300; end

    def update(dt : Float32) : Bool
      # Mover logic
      if move_and_collide?(dt)
        # Simple bounce by reversing direction
        self.dx = -self.dx.to_f32
        self.dy = -self.dy.to_f32
      end

      # Keep within world bounds
      if x < 0
        self.dx = self.dx.to_f32.abs.to_f32
      elsif x > WORLD_SIZE
        self.dx = -self.dx.to_f32.abs.to_f32
      end

      if y < 0
        self.dy = self.dy.to_f32.abs.to_f32
      elsif y > WORLD_SIZE
        self.dy = -self.dy.to_f32.abs.to_f32
      end

      super(dt)
      true
    end
  end

  class Player < GSDL::Sprite
    include GSDL::MoveController
    def initialize(x, y)
      super(
        key: "ship",
        x: x,
        y: y,
        origin: {0.5_f32, 0.5_f32},
        scale: {0.5_f32, 0.5_f32},
        source_rect: GSDL::FRect.new(0, 0, SHIP_SIZE, SHIP_SIZE)
      )
      self.tint = GSDL::Color::Magenta # High contrast
      self.z_index = 1000
    end

    def move_speed : GSDL::Num; 600; end

    def update(dt : Float32) : Bool
      self.move_input
      self.move_and_collide?(dt)
      super(dt)
      true
    end
  end

  class BenchmarkScene < GSDL::Scene
    include GSDL::SceneCollisions
    @player : Player?

    def initialize
      super(:benchmark)

      GSDL::Game.instance.performance_monitoring_enabled = true

      GSDL::Input.set(:move_left) { GSDL::Keys.pressed?([GSDL::Keys::A, GSDL::Keys::Left]) }
      GSDL::Input.set(:move_right) { GSDL::Keys.pressed?([GSDL::Keys::D, GSDL::Keys::Right]) }
      GSDL::Input.set(:move_up) { GSDL::Keys.pressed?([GSDL::Keys::W, GSDL::Keys::Up]) }
      GSDL::Input.set(:move_down) { GSDL::Keys.pressed?([GSDL::Keys::S, GSDL::Keys::Down]) }

      # Add many static obstacles
      150.times do
        x = Random.rand(WORLD_SIZE).to_f32
        y = Random.rand(WORLD_SIZE).to_f32

        # Avoid placing walls in the center safe zone (800-1200 range)
        next if x > 800 && x < 1200 && y > 800 && y < 1200

        w = Random.rand(32..64).to_f32
        h = Random.rand(32..64).to_f32
        add_child(Wall.new(x, y, w, h))
      end

      # Add some moving entities
      30.times do
        x = Random.rand(WORLD_SIZE).to_f32
        y = Random.rand(WORLD_SIZE).to_f32
        # Keep movers away from start too
        next if x > 800 && x < 1200 && y > 800 && y < 1200
        add_child(Mover.new(x, y))
      end

      # Add Player at center
      p = Player.new((WORLD_SIZE / 2.0).to_f32, (WORLD_SIZE / 2.0).to_f32)
      @player = add_child(p).as(Player)

      camera.type = GSDL::Camera::Type::CenterOnTarget
      camera.look_at(p)
      camera.lerp_speed = 0.0_f32 # Instant

      # Add Performance HUD
      h = GSDL::HUD.new
      h << GSDL::HUDPerformance.new(
        anchor: GSDL::Anchor::TopLeft,
        offset_x: 20,
        offset_y: 20,
        color: GSDL::Color::Yellow,
        align: GSDL::Font::Align::Left
      )
      self.hud = h
    end

    def update(dt : Float32)
      super(dt)
      if p = @player
        camera.look_at(p)
      end
      camera.update(dt)
    end
  end

  Game.new.run
end
