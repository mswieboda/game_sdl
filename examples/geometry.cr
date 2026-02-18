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
    @points : Array(GSDL::Point)
    @shapes : Array(GSDL::Shape)

    def initialize
      super(:start)

      @points = [] of GSDL::Point
      @shapes = [] of GSDL::Shape

      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)
      @points << GSDL::Pixel.new(x: 16, y: 16, color: color)

      color = GSDL.color(r: 255, g: 160, b: 224)
      @points << GSDL::Line.new(x1: 64, y1: 64, x2: 96, y2: 128, color: color)

      color = GSDL::Color::Blue
      @shapes << GSDL::Triangle.new({64, 16}, {96, 32}, {32, 48}, color: color)
      color = GSDL::Color::Magenta
      @shapes << GSDL::Triangle.new({64, 16}, {96, 32}, {32, 48}, color: color, draw_mode: GSDL::Shape::DrawMode::Outline)

      color = GSDL.color(r: 255)
      @shapes << GSDL::Box.new(x: 128, y: 128, width: 64, height: 96, color: color)
      @shapes << GSDL::Box.new(x: 256, y: 32, width: 64, height: 32, color: color, draw_mode: GSDL::Shape::DrawMode::Outline)

      color = GSDL::Color::LimeGreen
      @shapes << GSDL::Box.new(x: 320, y: 320, width: 96, height: 64, color: color, border_radius: 16)
      @shapes << GSDL::Box.new(x: 448, y: 256, width: 64, height: 128, color: color, border_radius: 64, draw_mode: GSDL::Shape::DrawMode::Outline)
      @shapes << GSDL::Circle.new(x: 320, y: 448, radius: 32, color: color)
      @shapes << GSDL::Oval.new(x: 448, y: 448, radius_x: 32, radius_y: 64, color: color)

      circle = GSDL::Circle.new(x: 400, y: 400, radius: 64, color: color, draw_mode: GSDL::Shape::DrawMode::Outline)
      @shapes << circle

      color = GSDL::Color::Blue
      @shapes << GSDL::Circle.new(x: 256, y: 320, radius: 64, color: color, draw_mode: GSDL::Shape::DrawMode::Outline)
      @shapes << GSDL::Oval.new(x: 224, y: 448, radius_x: 64, radius_y: 32, color: color)

      # example for changed, update_geometry
      circle.x = 319
      circle.y = 447
      circle.radius = 32.5_f32
      circle.draw_mode = GSDL::Shape::DrawMode::Outline
      circle.color = GSDL::Color::Magenta
    end

    def draw(draw : GSDL::Draw)
      @points.each(&.draw(draw))
      @shapes.each(&.draw(draw))

      color = GSDL::Color::Magenta
      GSDL::Pixel.draw(draw, [
        GSDL::Pixel.new(x: 128, y: 32, color: color),
        GSDL::Pixel.new(x: 160, y: 16, color: color),
        GSDL::Pixel.new(x: 160, y: 40, color: color),
        GSDL::Pixel.new(x: 160, y: 64, color: color),
        GSDL::Pixel.new(x: 192, y: 48, color: color),
      ])

      # can also use GSDL::Line.draw
      # with array of Points too
      # it should be the same
      color = GSDL::Color::Cyan
      GSDL::Pixel.draw_lines(draw, [
        GSDL::Pixel.new(x: 32, y: 128, color: color),
        GSDL::Pixel.new(x: 40, y: 136, color: color),
        GSDL::Pixel.new(x: 48, y: 144, color: color),
        GSDL::Pixel.new(x: 56, y: 136, color: color),
        GSDL::Pixel.new(x: 64, y: 152, color: color),
        GSDL::Pixel.new(x: 32, y: 256, color: color),
      ])
    end
  end

  Game.new.run
end
