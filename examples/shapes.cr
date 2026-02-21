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
      GSDL::Events.esc_exits = true
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
    @circle : GSDL::Circle
    @shapes = [] of GSDL::Shape
    @shape_index : Int32 = 0
    @draw_mode_index : Int32 = 0

    def initialize
      super(:start)

      color = GSDL::Color::LimeGreen

      text = "LEFT/RIGHT or A/D toggles shapes\n\nTAB toggles draw mode"
      @text_box = GSDL::TextBox.new(
        text: text,
        origin: {0.5_f32, 0.5_f32},
        color: color,
        align: GSDL::Font::Align::Center
      )
      @text_box.center(width: WIDTH, height: HEIGHT - HEIGHT + 128)

      @circle = GSDL::Circle.new(color: GSDL::Color::Magenta, radius: 6, z_index: 9)
      @circle.origin = {0.5_f32, 0.5_f32}
      @circle.center(width: WIDTH, height: HEIGHT)

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
      @shapes << GSDL::Line.new({32, 128}, {160, 96}, color: color, z_index: 3)
      @shapes << GSDL::Pixel.new(color: color)

      @shapes.each { |s| s.origin = {0.5_f32, 0.5_f32} }
      @shapes.each(&.center(width: WIDTH, height: HEIGHT))
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
      @circle.draw(draw) unless @shape_index == @shapes.size - 1
      @shapes[@shape_index].draw(draw)
    end
  end

  Game.new.run
end
