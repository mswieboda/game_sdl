require "../src/game_sdl"

# TODO: collision bounding boxes are off, i think it's just the example
module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Ball
    include GSDL::PhysicsController

    @x : GSDL::Num = 0
    @y : GSDL::Num = 0

    def x : GSDL::Num; @x; end
    def x=(x : GSDL::Num); @x = x; end
    def y : GSDL::Num; @y; end
    def y=(y : GSDL::Num); @y = y; end

    property radius : Float32 = 16_f32
    @circle : GSDL::Circle

    def initialize(@x, @y)
      @circle = GSDL::Circle.new(
        radius: radius,
        color: GSDL::Color.new(255, 0, 0, 255),
        origin: {0.5_f32, 0.5_f32}
      )
      self.restitution = 0.8_f32
      self.friction = 0.1_f32
      self.use_gravity = true
      self.velocity_x = 200_f32
        end

    def render_x : GSDL::Num; x; end
    def render_y : GSDL::Num; y; end
    def render_width : GSDL::Num; radius * 2; end
    def render_height : GSDL::Num; radius * 2; end

    def collision_bounding_box : GSDL::FRect
      GSDL::FRect.new(x: -radius, y: -radius, w: radius * 2, h: radius * 2)
    end

    def collision_shape : GSDL::Collidable::Shape
      GSDL::Collidable::Shape::Circle
    end

    def draw(draw : GSDL::Draw)
      @circle.x = x
      @circle.y = y
      @circle.draw(draw)
    end
  end

  class BouncingTriangle
    include GSDL::PhysicsController

    @x : GSDL::Num = 0
    @y : GSDL::Num = 0

    def x : GSDL::Num; @x; end
    def x=(x : GSDL::Num); @x = x; end
    def y : GSDL::Num; @y; end
    def y=(y : GSDL::Num); @y = y; end

    @triangle : GSDL::Triangle

    def initialize(@x, @y)
      @triangle = GSDL::Triangle.new(
        p1: {0, -32},
        p2: {32, 32},
        p3: {-32, 32},
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color.new(0, 0, 255, 255)
      )
      self.restitution = 0.6_f32
      self.friction = 0.2_f32
      self.use_gravity = true
      self.velocity_x = -150_f32
    end

    def render_x : GSDL::Num; x; end
    def render_y : GSDL::Num; y; end
    def collision_bounding_box : GSDL::FRect
      @triangle.collision_bounding_box
    end

    def collision_shape : GSDL::Collidable::Shape
      @triangle.collision_shape
    end

    def collision_polygon_vertices : GSDL::Points
      @triangle.x = x
      @triangle.y = y
      @triangle.collision_polygon_vertices
    end

    def update(dt : Float32)
      @triangle.rotation += 180 * dt # Rotate 180 degrees per second
    end

    def draw(draw : GSDL::Draw)
      @triangle.x = x
      @triangle.y = y
      @triangle.draw(draw)
    end
  end

  class BouncingBox
    include GSDL::PhysicsController

    @x : GSDL::Num = 0
    @y : GSDL::Num = 0

    def x : GSDL::Num; @x; end
    def x=(x : GSDL::Num); @x = x; end
    def y : GSDL::Num; @y; end
    def y=(y : GSDL::Num); @y = y; end

    @box : GSDL::Box

    def initialize(@x, @y)
      @box = GSDL::Box.new(
        width: 64,
        height: 64,
        color: GSDL::Color.new(255, 255, 0, 255),
        origin: {0.5_f32, 0.5_f32}
      )
      self.restitution = 0.4_f32
      self.friction = 0.3_f32
      self.use_gravity = true
      self.velocity_x = 300_f32
    end

    def render_x : GSDL::Num; x; end
    def render_y : GSDL::Num; y; end
    def collision_bounding_box : GSDL::FRect
      @box.collision_bounding_box
    end

    def collision_shape : GSDL::Collidable::Shape
      @box.collision_shape
    end

    def collision_polygon_vertices : GSDL::Points
      @box.x = x
      @box.y = y
      @box.collision_polygon_vertices
    end

    def update(dt : Float32)
      @box.rotation += 90 * dt
    end

    def draw(draw : GSDL::Draw)
      @box.x = x
      @box.y = y
      @box.draw(draw)
    end
  end

  class BouncingOval
    include GSDL::PhysicsController

    @x : GSDL::Num = 0
    @y : GSDL::Num = 0

    def x : GSDL::Num; @x; end
    def x=(x : GSDL::Num); @x = x; end
    def y : GSDL::Num; @y; end
    def y=(y : GSDL::Num); @y = y; end

    @oval : GSDL::Oval

    def initialize(@x, @y)
      @oval = GSDL::Oval.new(
        radius_x: 64,
        radius_y: 32,
        color: GSDL::Color.new(0, 255, 255, 255),
        origin: {0.5_f32, 0.5_f32}
      )
      self.restitution = 0.7_f32
      self.friction = 0.1_f32
      self.use_gravity = true
    end

    def render_x : GSDL::Num; x; end
    def render_y : GSDL::Num; y; end
    def collision_bounding_box : GSDL::FRect
      @oval.collision_bounding_box
    end

    def collision_shape : GSDL::Collidable::Shape
      @oval.collision_shape
    end

    def collision_polygon_vertices : GSDL::Points
      @oval.x = x
      @oval.y = y
      @oval.collision_polygon_vertices
    end

    def update(dt : Float32)
      @oval.rotation += 120 * dt
    end

    def draw(draw : GSDL::Draw)
      @oval.x = x
      @oval.y = y
      @oval.draw(draw)
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

    def render_x : GSDL::Num; x; end
    def render_y : GSDL::Num; y; end
    def collision_bounding_box : GSDL::FRect
      GSDL::FRect.new(x: 0, y: 0, w: w, h: h)
    end

    def draw(draw : GSDL::Draw)
      draw.rect_fill(rect: GSDL::Rect.new(x: x.to_i, y: y.to_i, w: w.to_i, h: h.to_i), color: GSDL::Color.new(100, 100, 100, 255))
    end
  end

  class Game < GSDL::Game
    def initialize
      super(title: "Physics Bouncing Ex")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Physics.gravity = {0, 500}
      GSDL::Game.push(PhysicsScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class PhysicsScene < GSDL::Scene
    @ball : Ball
    @triangle : BouncingTriangle
    @box : BouncingBox
    @oval : BouncingOval
    @walls : Array(GSDL::Collidable)
    @text : GSDL::Text

    def initialize
      super(:physics)
      @ball = Ball.new(100, 100)
      @triangle = BouncingTriangle.new(WIDTH - 100, 100)
      @box = BouncingBox.new(WIDTH // 2, 50)
      @oval = BouncingOval.new(WIDTH // 2 + 100, 50)
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

      @text = GSDL::Text.new(
        text: "Press SPACE for random impulse",
        color: GSDL::Color::White
      )
      @text.x = 30
      @text.y = 30
    end

    def update(dt : Float32)
      objs = [@ball.as(GSDL::Collidable), @triangle.as(GSDL::Collidable), @box.as(GSDL::Collidable), @oval.as(GSDL::Collidable)]

      @ball.physics_update(dt, @walls + (objs - [@ball.as(GSDL::Collidable)]))
      @triangle.update(dt)
      @triangle.physics_update(dt, @walls + (objs - [@triangle.as(GSDL::Collidable)]))
      @box.update(dt)
      @box.physics_update(dt, @walls + (objs - [@box.as(GSDL::Collidable)]))
      @oval.update(dt)
      @oval.physics_update(dt, @walls + (objs - [@oval.as(GSDL::Collidable)]))

      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        # Apply random impulses
        [@ball, @triangle, @box, @oval].each do |obj|
          obj.velocity_x = Random.rand(-400_f32..400_f32)
          obj.velocity_y = Random.rand(-600_f32..-200_f32)
        end
      end
    end

    def draw(draw : GSDL::Draw)
      @walls.each do |w|
        w.as(Wall).draw(draw)
      end
      @ball.draw(draw)
      @triangle.draw(draw)
      @box.draw(draw)
      @oval.draw(draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
