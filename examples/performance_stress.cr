require "../src/game_sdl"

module StressEx
  WIDTH = 800
  HEIGHT = 600
  ENTITY_COUNT = 2000
  WORLD_SIZE = 4000

  class Game < GSDL::Game
    def initialize
      super(title: "Performance Stress Test", width: WIDTH, height: HEIGHT)
    end

    def init
      GSDL::Events.esc_exits = true
      self.target_fps = 60
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
      super(key: "player", width: 32, height: 64, x: x, y: y, origin: {0.5_f32, 0.5_f32})
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
      super(key: "ship", x: x, y: y, origin: {0.5_f32, 0.5_f32})
      self.z_index = 0
    end

    def update(dt : Float32)
      return unless super(dt)
      self.rotation += 45.0_f32 * dt
    end
  end

  class StressScene < GSDL::Scene
    @entities = [] of GSDL::SpriteBase
    @fps_text : GSDL::Text
    @count_text : GSDL::Text

    def initialize
      super(:stress)

      GSDL::Input.set(:camera_left) { GSDL::Keys.pressed?([GSDL::Keys::A, GSDL::Keys::Left]) }
      GSDL::Input.set(:camera_right) { GSDL::Keys.pressed?([GSDL::Keys::D, GSDL::Keys::Right]) }
      GSDL::Input.set(:camera_up) { GSDL::Keys.pressed?([GSDL::Keys::W, GSDL::Keys::Up]) }
      GSDL::Input.set(:camera_down) { GSDL::Keys.pressed?([GSDL::Keys::S, GSDL::Keys::Down]) }

      ENTITY_COUNT.times do        x = Random.rand(WORLD_SIZE).to_f32
        y = Random.rand(WORLD_SIZE).to_f32

        if Random.rand > 0.5
          @entities << Skeleton.new(x, y)
        else
          @entities << Ship.new(x, y)
        end
      end

      camera.speed = 1000 # High speed for flying around
      camera.type = GSDL::Camera::Type::Manual

      @fps_text = GSDL::Text.new(text: "FPS: 0", x: 10, y: 10, color: GSDL::Color::Lime)
      @fps_text.draw_relative_to_camera = false

      @count_text = GSDL::Text.new(text: "Entities: #{ENTITY_COUNT}", x: 10, y: 40, color: GSDL::Color::White)
      @count_text.draw_relative_to_camera = false
    end

    def update(dt : Float32)
      @entities.each(&.update(dt))
      camera.update(dt)

      @fps_text.text = "FPS: #{GSDL::Game.fps}"
      @count_text.text = "Entities: #{ENTITY_COUNT} | Cmds: #{GSDL::Game.draw.command_count}"
    end
    def draw(draw : GSDL::Draw)
      # Draw world bounds for reference
      draw.rect_outline(
        rect: GSDL::FRect.new(-camera.x, -camera.y, WORLD_SIZE, WORLD_SIZE),
        color: GSDL::Color::Red
      )

      @entities.each(&.draw(draw))

      @fps_text.draw(draw)
      @count_text.draw(draw)
    end
  end

  Game.new.run
end
