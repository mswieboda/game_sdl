require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Shape Example", width: WIDTH, height: HEIGHT)
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
    @index : Int32 = 0
    @pixel : GSDL::Pixel
    @shapes : Array(GSDL::Shape) = [] of GSDL::Shape

    def initialize
      super(:start)

      color = GSDL::Color::LimeGreen

      x = 300
      y = 200

      @pixel = GSDL::Pixel.new(x: x, y: y, color: color)

      @shapes << GSDL::Triangle.new({64, 16}, {96, 32}, {32, 48}, color: color)
      @shapes << GSDL::Box.new(x: x, y: y, width: 64, height: 96, color: color)
      @shapes << GSDL::Box.new(x: x, y: y, width: 96, height: 64, color: color, border_radius: 16)
      @shapes << GSDL::Circle.new(x: x, y: y, radius: 32, color: color)
      @shapes << GSDL::Oval.new(x: x, y: y, radius_x: 32, radius_y: 64, color: color)
      @shapes << GSDL::Arc.new(x: x, y: y, radius_x: 64, radius_y: 32, color: color)
    end

    def update(dt : Float32)
      if Keys.just_pressed?([Keys::A, Keys::Left])
        @index += 1
        @index = 0 if @index >= @shapes.size
      elsif Keys.just_pressed?([Keys::D, Keys::Right])
        @index -= 1
        @index = @shapes.size - 1 if @index < 0
      end
    end

    def draw(draw : GSDL::Draw)
      @pixel.draw(draw)
      @shapes[@index].draw(draw)
    end
  end

  Game.new.run
end
