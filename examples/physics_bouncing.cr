require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Ball
    include GSDL::PhysicsController

    @x : GSDL::Num = 0
    @y : GSDL::Num = 0

    def x : GSDL::Num; @x; end
    def x=(value : GSDL::Num); @x = value; end
    def y : GSDL::Num; @y; end
    def y=(value : GSDL::Num); @y = value; end

    property radius : Float32 = 15_f32
    @circle : GSDL::Circle

    def initialize(@x, @y)
      @circle = GSDL::Circle.new(radius: radius, color: GSDL::Color.new(255, 0, 0, 255))
      self.restitution = 0.8_f32
      self.use_gravity = true
      self.velocity_x = 200_f32
    end

    def draw_x : GSDL::Num; x; end
    def draw_y : GSDL::Num; y; end
    def draw_width : GSDL::Num; radius * 2; end
    def draw_height : GSDL::Num; radius * 2; end

    def collision_bounding_box : GSDL::FRect
      GSDL::FRect.new(x: -radius, y: -radius, w: radius * 2, h: radius * 2)
    end

    def draw(draw : GSDL::Draw)
      @circle.x = x
      @circle.y = y
      @circle.draw(draw)
    end
  end

  class Wall
    include GSDL::Collidable
    property x : GSDL::Num = 0
    property y : GSDL::Num = 0
    property w : GSDL::Num = 0
    property h : GSDL::Num = 0

    def initialize(@x, @y, @w, @h)
    end

    def draw_x : GSDL::Num; x; end
    def draw_y : GSDL::Num; y; end
    def collision_bounding_box : GSDL::FRect
      GSDL::FRect.new(x: 0, y: 0, w: w, h: h)
    end

    def draw(draw : GSDL::Draw)
      draw.rect_fill(rect: GSDL::Rect.new(x: x.to_i, y: y.to_i, w: w.to_i, h: h.to_i), color: GSDL::Color.new(100, 100, 100, 255))
    end
  end

  class Game < GSDL::Game
    def initialize
      super(title: "Physics Bouncing Ex", width: WIDTH, height: HEIGHT)
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Physics.gravity = {0, 500}
      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = PhysicsScene.new
    end
  end

  class PhysicsScene < GSDL::Scene
    @ball : Ball
    @walls : Array(GSDL::Collidable)

    def initialize
      super(:physics)
      @ball = Ball.new(100, 100)
      @walls = [] of GSDL::Collidable
      # Floor
      @walls << Wall.new(0, HEIGHT - 20, WIDTH, 20)
      # Ceiling
      @walls << Wall.new(0, 0, WIDTH, 20)
      # Left wall
      @walls << Wall.new(0, 0, 20, HEIGHT)
      # Right wall
      @walls << Wall.new(WIDTH - 20, 0, 20, HEIGHT)
      # Obstacle
      @walls << Wall.new(WIDTH // 2 - 50, HEIGHT // 2 + 50, 100, 40)
    end

    def update(dt : Float32)
      @ball.physics_update(dt, @walls)
      
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        @ball.velocity_y = -400_f32
      end
    end

    def draw(draw : GSDL::Draw)
      @walls.each do |w|
        w.as(Wall).draw(draw)
      end
      @ball.draw(draw)
    end
  end

  Game.new.run
end
