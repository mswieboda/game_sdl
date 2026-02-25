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
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_fonts
      GSDL::FontManager.load_default("fonts/PressStart2P.ttf")
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

  class Enemy < GSDL::Sprite
    def initialize(x : GSDL::Num, y : GSDL::Num)
      source_rect = GSDL::FRect.new(w: 128)

      super(
        key: "ship",
        x: x,
        y: y,
        origin: {0.5_f32, 0.5_f32},
        source_rect: source_rect
      )
    end

    def draw(draw)
      super(draw)

      draw_box(draw, area_box, GSDL::Color::Yellow)
      draw_box(draw, collision_box, GSDL::Color::Red)
    end

    def draw_box(draw, box, color)
      draw.rect_outline(box, color, z_index: 9)
    end
  end

  class Player < Enemy
    include GSDL::MoveController

    def area_bounding_box : GSDL::FRect
      GSDL::FRect.new(-32, -32, width + 64)
    end

    def collision_bounding_box : GSDL::FRect
      GSDL::FRect.new(24, 24, 80)
    end

    def move_speed : GSDL::Num
      200
    end
  end

  class StartScene < GSDL::Scene
    @text : GSDL::Text
    @enemy : Enemy
    @player : Player

    def initialize
      super(:start)

      @text = GSDL::Text.new(text: "", y: 32, origin: {0.5_f32, 0.5_f32})
      @text.x = WIDTH / 2_f32

      @enemy = Enemy.new(x: 320, y: 320)
      @player = Player.new(x: 128, y: 128)
    end

    def update(dt : Float32)
      if @player.move_and_collide?(dt, [@enemy])
        @text.text = "collision!"
      elsif @enemy.in?(@player)
        @text.text = "enemy in area!"
      elsif !@text.text.empty?
        @text.text = ""
      end
    end

    def draw(draw : GSDL::Draw)
      @enemy.draw(draw)
      @player.draw(draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
