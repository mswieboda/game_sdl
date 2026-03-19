require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias Input = GSDL::Input

  class Game < GSDL::Game
    def initialize
      super(title: "Collision Ex", width: 800, height: 640)
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(StartScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [{"ship", "gfx/ship.png"}]
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

  class CircleObject < GSDL::Circle
    include GSDL::Collidable

    def collision_bounding_box : GSDL::FRect
      GSDL::FRect.new(x: radius / 2_f32, y: radius / 2_f32, w: radius, h: radius)
    end

    def collision_shape : GSDL::Collidable::Shape
      GSDL::Collidable::Shape::Circle
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
    @circle : CircleObject

    def initialize
      super(:start)

      Input.set(:move_left) { Keys.pressed?([Keys::A, Keys::Left]) }
      Input.set(:move_right) { Keys.pressed?([Keys::D, Keys::Right]) }
      Input.set(:move_up) { Keys.pressed?([Keys::W, Keys::Up]) }
      Input.set(:move_down) { Keys.pressed?([Keys::S, Keys::Down]) }

      @text = GSDL::Text.new(text: "", y: 32, origin: {0.5_f32, 0.5_f32})
      @text.x = Game.width / 2_f32

      @enemy = Enemy.new(x: 320, y: 320)
      @player = Player.new(x: 128, y: 128)
      @circle = CircleObject.new(x: 512, y: 448, radius: 128, origin: {0.5_f32, 0.5_f32})
    end

    def update(dt : Float32)
      @player.move_input

      if @player.move_and_collide?(dt, [@enemy, @circle.as(GSDL::Collidable)])
        @text.text = "collision!"
      elsif @player.overlaps?(@enemy)
        @text.text = "enemy in area!"
      elsif @player.overlaps?(@circle)
        @text.text = "circle in area!"
      elsif !@text.text.empty?
        @text.text = ""
      end
    end

    def draw(draw : GSDL::Draw)
      @enemy.draw(draw)
      @player.draw(draw)
      @circle.draw(draw)

      @text.draw(draw)
    end
  end

  Game.new.run
end
