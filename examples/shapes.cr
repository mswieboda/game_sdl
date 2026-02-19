require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Shapes Example", width: WIDTH, height: HEIGHT)
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
    @text_box : GSDL::TextBox
    @points = [] of GSDL::Point
    @circle : GSDL::Circle
    @shapes = [] of GSDL::Shape
    @shape_index : Int32 = 0
    @draw_mode_index : Int32 = 0

    def initialize
      super(:start)

      color = GSDL::Color::LimeGreen

      text = "LEFT/RIGHT or A/D toggles shapes\n\nTAB toggles draw mode"
      @text_box = GSDL::TextBox.new(text: text, color: color, align: GSDL::Font::Align::Center)
      @text_box.center(WIDTH, HEIGHT - HEIGHT + 128)

      @points << GSDL::Pixel.new(x: 32, y: 32, color: color, z_index: 3)
      @points << GSDL::Pixel.new({32, 64}, color: color)
      @points << GSDL::Pixel.new({32, 96}, color: color)
      @points << GSDL::Line.new({32, 128}, {WIDTH - 32, 128}, color: color, z_index: 3)

      @circle = GSDL::Circle.new(color: GSDL::Color::Magenta, radius: 8, z_index: 9)
      @circle.origin = {0.5_f32, 0.5_f32}
      @circle.center(WIDTH, HEIGHT)

      w = 100
      h = 200
      r_x = (w / 2).to_f32
      r_y = (h / 2).to_f32
      border_thickness = 8

      @shapes << GSDL::Triangle.new({64, 16}, {96, 32}, {32, 48}, color: color, border_thickness: border_thickness)
      @shapes << GSDL::Box.new(width: w, height: h, color: color, border_thickness: border_thickness)
      @shapes << GSDL::Box.new(width: w, height: h, color: color, border_thickness: border_thickness, border_radius: 16)
      @shapes << GSDL::Oval.new(radius_x: r_x, radius_y: r_y, color: color, border_thickness: border_thickness)
      @shapes << GSDL::Circle.new(radius: r_y, color: color, border_thickness: border_thickness)
      @shapes << GSDL::Pie.new(radius: r_y, color: color, border_thickness: border_thickness)

      @shapes.each { |s| s.origin = {0.5_f32, 0.5_f32} }
      @shapes.each(&.center(WIDTH, HEIGHT))
    end

    def update(dt : Float32)
      if Keys.just_pressed?([Keys::A, Keys::Left])
        @shape_index -= 1
        @shape_index = @shapes.size - 1 if @shape_index < 0

        update_draw_mode
      elsif Keys.just_pressed?([Keys::D, Keys::Right])
        @shape_index += 1
        @shape_index = 0 if @shape_index >= @shapes.size

        update_draw_mode
      elsif Keys.just_pressed?(Keys::Tab)
        @draw_mode_index += 1
        @draw_mode_index = 0 if @draw_mode_index >= GSDL::Shape::DrawMode.values.size
        @draw_mode_index = GSDL::Shape::DrawMode.values.size - 1 if @draw_mode_index < 0

        update_draw_mode
      end
    end

    def update_draw_mode
      shape = @shapes[@shape_index]
      draw_mode = GSDL::Shape::DrawMode.values[@draw_mode_index]
      shape.draw_mode = draw_mode if shape.draw_mode != draw_mode
    end

    def draw(draw : GSDL::Draw)
      @text_box.draw(draw)
      @points.each(&.draw(draw))
      @circle.draw(draw)
      @shapes[@shape_index].draw(draw)

      draw.points(
        points: [
          GSDL::Point.new(x: WIDTH - 32, y: 32),
          GSDL::Point.new({WIDTH - 32, 64}),
          GSDL::Pixel.new({WIDTH - 32, 96})
        ],
        color: GSDL::Color::Magenta,
        z_index: 9
      )
    end
  end

  Game.new.run
end
