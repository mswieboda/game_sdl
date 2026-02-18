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

    def load_fonts
      GSDL::FontManager.load_default("fonts/PressStart2P.ttf")
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @shape_index : Int32 = 0
    @draw_mode_index : Int32 = 0
    @circle : GSDL::Circle
    @shapes : Array(GSDL::Shape) = [] of GSDL::Shape
    @text_box : GSDL::TextBox

    def initialize
      super(:start)

      color = GSDL::Color::LimeGreen

      w = 100
      h = 200
      r_x = (w / 2).to_f32
      r_y = (h / 2).to_f32

      text = "LEFT/RIGHT or A/D toggles shapes\n\nTAB toggles draw mode"
      @text_box = GSDL::TextBox.new(text: text, color: color, align: GSDL::Font::Align::Center)

      @circle = GSDL::Circle.new(color: GSDL::Color::Magenta, radius: 8)

      @shapes << GSDL::Triangle.new({64, 16}, {96, 32}, {32, 48}, color: color)
      @shapes << GSDL::Box.new(width: w, height: h, color: color)
      @shapes << GSDL::Box.new(width: w, height: h, color: color, border_radius: 16)
      @shapes << GSDL::Oval.new(radius_x: r_x, radius_y: r_y, color: color)
      @shapes << GSDL::Circle.new(radius: r_y, color: color)
      @shapes << GSDL::Arc.new(radius_x: r_x, radius_y: r_y, color: color)

      @text_box.center(WIDTH, HEIGHT - HEIGHT + 128)
      @circle.center(WIDTH, HEIGHT)
      @shapes.each(&.center(WIDTH, HEIGHT))
    end

    def update(dt : Float32)
      if Keys.just_pressed?([Keys::A, Keys::Left])
        @shape_index -= 1
        @shape_index = @shapes.size - 1 if @shape_index < 0
      elsif Keys.just_pressed?([Keys::D, Keys::Right])
        @shape_index += 1
        @shape_index = 0 if @shape_index >= @shapes.size
      elsif Keys.just_pressed?(Keys::Tab)
        @draw_mode_index += 1
        @draw_mode_index = 0 if @draw_mode_index >= GSDL::Shape::DrawMode.values.size
        @draw_mode_index = GSDL::Shape::DrawMode.values.size - 1 if @draw_mode_index < 0

        shape = @shapes[@shape_index]
        shape.draw_mode = GSDL::Shape::DrawMode.values[@draw_mode_index]
      end
    end

    def draw(draw : GSDL::Draw)
      @shapes[@shape_index].draw(draw)
      @circle.draw(draw)
      @text_box.draw(draw)
    end
  end

  Game.new.run
end
