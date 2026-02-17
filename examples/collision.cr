require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Collision Ex", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
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
    @player : GSDL::Sprite
    @obstacle : GSDL::Sprite

    def initialize
      super(:start)

      source_rect = GSDL::FRect.new(x: 0_f32, y: 0_f32, w: 128_f32, h: 128_f32)
      @player = GSDL::Sprite.new(key: "ship", x: 100_f32, y: 100_f32, source_rect: source_rect)
      @obstacle = GSDL::Sprite.new(key: "ship", x: 400_f32, y: 300_f32, source_rect: source_rect)
    end

    def update(dt : Float32)
      speed = 200 * dt

      previous_x = @player.x
      previous_y = @player.y

      if Keys.pressed?([Keys::A, Keys::Left])
        @player.x -= speed
      end
      if Keys.pressed?([Keys::D, Keys::Right])
        @player.x += speed
      end
      if Keys.pressed?([Keys::W, Keys::Up])
        @player.y -= speed
      end
      if Keys.pressed?([Keys::S, Keys::Down])
        @player.y += speed
      end

      if @player.collides?(@obstacle)
        @player.x = previous_x
        @player.y = previous_y
      end
    end

    def draw(draw : GSDL::Draw)
      @player.draw(draw)
      @obstacle.draw(draw)

      # Draw a green box around the player to visualize its bounding box
      draw.color = GSDL::Color::Green
      draw.outline(@player.collision_box)

      # Draw a red box around the obstacle to visualize its bounding box
      draw.color = GSDL::Color::Red
      draw.outline(@obstacle.collision_box)
    end
  end

  Game.new.run
end
