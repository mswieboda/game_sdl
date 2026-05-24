require "../src/game_sdl"

module StressEx
  WIDTH = 800
  HEIGHT = 600
  ENTITY_COUNT = 2000
  WORLD_SIZE = 4000

  class Game < GSDL::Game
    def initialize
      super(title: "Performance Stress Test")
    end

    def init
      GSDL::Events.esc_exits = true
      self.target_fps = 60
      # Enable performance monitoring
      self.performance_monitoring_enabled = true
      GSDL::Game.push(StressScene.new)
    end

    def load_textures
      [
        {"player", "gfx/skeleton.png"},
        {"ship", "gfx/ship.png"}
      ]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class Skeleton < GSDL::AnimatedSprite
    def initialize(x, y)
      super(key: :player, width: 32, height: 64, x: x, y: y, origin: {0.5_f32, 0.5_f32})
      add("walk", (1..6).to_a, 8)
      play("walk")
      self.z_index = 1
    end

    def update(dt : Float32)
      return unless super(dt)
      # Some very light movement logic
      @x += Math.sin(GSDL.ticks / 1000.0_f32 + x) * 10.0_f32 * dt
    end
  end

  class Ship < GSDL::Sprite
    def initialize(x, y)
      super(key: :ship, x: x, y: y, origin: {0.5_f32, 0.5_f32})
      self.z_index = 0
      self.rotation += 45.0_f32
    end

    def update(dt : Float32)
      return unless super(dt)
      self.rotation += 45.0_f32 * dt
    end
  end

  class StressScene < GSDL::Scene
    @entities = [] of GSDL::Entity
    @timer : GSDL::Timer

    def initialize
      super(:stress)
      @timer = GSDL::Timer.new(3.seconds)
      @timer.start

      GSDL::Input.set(:camera_left) { GSDL::Keys.pressed?([GSDL::Keys::A, GSDL::Keys::Left]) }
      GSDL::Input.set(:camera_right) { GSDL::Keys.pressed?([GSDL::Keys::D, GSDL::Keys::Right]) }
      GSDL::Input.set(:camera_up) { GSDL::Keys.pressed?([GSDL::Keys::W, GSDL::Keys::Up]) }
      GSDL::Input.set(:camera_down) { GSDL::Keys.pressed?([GSDL::Keys::S, GSDL::Keys::Down]) }

      rng = Random.new(42)
      ENTITY_COUNT.times do
        x = rng.rand(WORLD_SIZE).to_f32
        y = rng.rand(WORLD_SIZE).to_f32

        entity = if rng.rand > 0.5
          Skeleton.new(x, y)
        else
          Ship.new(x, y)
        end

        # 25% of entities get a tint
        if rng.rand < 0.25
          case rng.rand(3)
          when 0 # Red 50% alpha
            entity.tint = GSDL::Color.new(255, 0, 0, 128)
          when 1 # Green 75% alpha
            entity.tint = GSDL::Color.new(0, 255, 0, 191)
          when 2 # Blue 25% alpha
            entity.tint = GSDL::Color.new(0, 0, 255, 64)
          end
        end

        @entities << entity
      end

      camera.speed = 1000 # High speed for flying around
      camera.type = GSDL::Camera::Type::Manual

      # # Add Performance HUD
      # h = GSDL::HUD.new
      # h << GSDL::HUDPerformance.new(
      #   anchor: GSDL::Anchor::TopLeft,
      #   offset_x: 20,
      #   offset_y: 20,
      #   color: GSDL::Color::Yellow
      # )
      # self.hud = h
    end

    def update(dt : Float32)
      if @timer.done?
        GSDL::Game.quit!
        return
      end

      super(dt)

      # Automatic camera movement (Circular pattern)
      t = @timer.percent
      camera.x = (Math.sin(t * Math::PI * 2) * (WORLD_SIZE - WIDTH) / 2 + (WORLD_SIZE - WIDTH) / 2).to_f32
      camera.y = (Math.cos(t * Math::PI * 2) * (WORLD_SIZE - HEIGHT) / 2 + (WORLD_SIZE - HEIGHT) / 2).to_f32

      @entities.each(&.update(dt))
      camera.update(dt)
    end
  end

  Game.new.run
end
