require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Geometry Example", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @filled : Array(GSDL::Shape)
    @outlines : Array(GSDL::Shape)

    def initialize
      super(:start)

      @filled = [] of GSDL::Shape
      @outlines = [] of GSDL::Shape

      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)
      @filled << GSDL::Point.new(x: 32, y: 32, color: color)

      color = GSDL.color(r: 255, g: 160, b: 224)
      @filled << GSDL::Line.new(x1: 64, y1: 64, x2: 96, y2: 128, color: color)

      color = GSDL.color(r: 255)
      @filled << GSDL::Box.new(x: 128, y: 128, width: 64, height: 96, color: color)
      @outlines << GSDL::Box.new(x: 32, y: 32, width: 64, height: 32, color: color)

      color = GSDL::Color::LimeGreen
      @filled << GSDL::Box.new(x: 320, y: 320, width: 96, height: 64, color: color, border_radius: 16)
      @outlines << GSDL::Box.new(x: 448, y: 256, width: 64, height: 128, color: color, border_radius: 64)
      @filled << GSDL::Circle.new(x: 320, y: 448, radius: 32, color: color)
      @filled << GSDL::Oval.new(x: 448, y: 448, radius_x: 32, radius_y: 64, color: color)

      circle = GSDL::Circle.new(x: 400, y: 400, radius: 64, color: color)
      @outlines << circle

      color = GSDL::Color::Blue
      @outlines << GSDL::Circle.new(x: 256, y: 320, radius: 64, color: color)
      @filled << GSDL::Oval.new(x: 224, y: 448, radius_x: 64, radius_y: 32, color: color)

      # example for changed, update_geometry
      circle.x = 319
      circle.y = 447
      circle.radius = 32.5_f32
      circle.color = GSDL::Color::Magenta
    end

    def draw(draw : GSDL::Draw)
      @filled.each(&.draw(draw))
      @outlines.each(&.draw_outline(draw))

      color = GSDL::Color::Magenta
      GSDL::Point.draw(draw, [
        GSDL::Point.new(x: 128, y: 32, color: color),
        GSDL::Point.new(x: 136, y: 40, color: color),
        GSDL::Point.new(x: 144, y: 48, color: color),
      ])

      # can also use GSDL::Line.draw
      # with array of Points too
      # it should be the same
      color = GSDL::Color::Cyan
      GSDL::Point.draw_lines(draw, [
        GSDL::Point.new(x: 32, y: 128, color: color),
        GSDL::Point.new(x: 40, y: 136, color: color),
        GSDL::Point.new(x: 48, y: 144, color: color),
        GSDL::Point.new(x: 56, y: 136, color: color),
        GSDL::Point.new(x: 64, y: 152, color: color),
        GSDL::Point.new(x: 32, y: 256, color: color),
      ])

      color = GSDL::Color::Yellow
      GSDL::Box.draw_outlines(draw, [
        GSDL::Box.new(x: 256, y: 128, width: 32, height: 32, color: color),
        GSDL::Box.new(x: 272, y: 144, width: 64, height: 64, color: color),
        GSDL::Box.new(x: 312, y: 184, width: 48, height: 48, color: color),
      ])
    end
  end

  Game.new.run
end
