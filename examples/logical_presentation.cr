require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias Text = GSDL::Text

  WIDTH = 800
  HEIGHT = 800
  LOGICAL_WIDTH = 320
  LOGICAL_HEIGHT = 240

  class Game < GSDL::Game
    def initialize
      super(title: "Logical Presentation Example", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
      @draw.set_logical_presentation(LOGICAL_WIDTH, LOGICAL_HEIGHT, SDL3::LogicalPresentation::Disabled)
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
    @instruction_text : GSDL::Text
    @mode_text : GSDL::Text
    @logical_size_text : GSDL::Text
    @window_size_text : GSDL::Text
    @background_texture : SDL3::Texture

    @presentation_modes : Array(SDL3::LogicalPresentation) = [
      SDL3::LogicalPresentation::Disabled,
      SDL3::LogicalPresentation::Stretch,
      SDL3::LogicalPresentation::Letterbox,
      SDL3::LogicalPresentation::Overscan,
      SDL3::LogicalPresentation::IntegerScale,
    ]
    @presentation_mode_names = [
      "DISABLED",
      "STRETCH",
      "LETTERBOX",
      "OVERSCAN",
      "INTEGER_SCALE",
    ]
    @current_mode_index = 0

    def initialize
      super(:logical_presentation)

      color = GSDL::Color.new(r: 255, g: 255, b: 255, a: 255)

      @instruction_text = GSDL::Text.new(text: "Press SPACE to change presentation mode. ESC to exit.", color: color)
      @instruction_text.x = 10
      @instruction_text.y = 10

      @mode_text = GSDL::Text.new(text: "Mode: DISABLED", color: color)
      @mode_text.x = 10
      @mode_text.y = 40

      @logical_size_text = GSDL::Text.new(text: "Logical Size: #{LOGICAL_WIDTH}x#{LOGICAL_HEIGHT}", color: color)
      @logical_size_text.x = 10
      @logical_size_text.y = 70

      @window_size_text = GSDL::Text.new(text: "Window Size: #{WIDTH}x#{HEIGHT}", color: color)
      @window_size_text.x = 10
      @window_size_text.y = 100

      # Create a checkerboard background surface (fills logical area)
      surface = SDL3::Surface.new(LOGICAL_WIDTH, LOGICAL_HEIGHT)
      unless surface
        raise "Failed to create checkerboard surface: #{SDL3.get_error}"
      end

      # Draw checkerboard pattern
      tile_size = 20
      color1 = GSDL.color(50, 50, 50, 255) # Dark gray
      color2 = GSDL.color(150, 150, 150, 255) # Light gray

      (0...LOGICAL_HEIGHT).step(tile_size) do |y|
        (0...LOGICAL_WIDTH).step(tile_size) do |x|
          rect = GSDL::Rect.new(x: x, y: y, w: tile_size, h: tile_size)
          if ((x / tile_size) + (y / tile_size)) % 2 == 0
            surface.fill_rect(rect, color1)
          else
            surface.fill_rect(rect, color2)
          end
        end
      end


      @background_texture = Game.draw_instance.create_texture(surface)
    end

    def update(dt : Float32)
      if Keys.just_pressed?(Keys::Escape)
        @exit = true
        return
      end

      if Keys.just_pressed?(Keys::Space)
        @current_mode_index = (@current_mode_index + 1) % @presentation_modes.size
        mode = @presentation_modes[@current_mode_index]
        Game.draw_instance.set_logical_presentation(LOGICAL_WIDTH, LOGICAL_HEIGHT, mode)
        @mode_text.text = "Mode: #{@presentation_mode_names[@current_mode_index]}"
        puts "Switched logical presentation to: #{@presentation_mode_names[@current_mode_index]}"
      end
    end

    def draw(draw : GSDL::Draw)
      # Clear with a distinct color to show letterboxing/overscan areas
      draw.color = GSDL::Colors::Magenta
      draw.clear

      # Render background, which will be scaled by the logical presentation
      bg_dst_rect = GSDL::FRect.new(x: 0.0, y: 0.0, w: LOGICAL_WIDTH.to_f32, h: LOGICAL_HEIGHT.to_f32)
      draw.texture(@background_texture, bg_dst_rect)

      # Render text
      @instruction_text.draw(draw)
      @mode_text.draw(draw)
      @logical_size_text.draw(draw)
      @window_size_text.draw(draw)
    end

    def destroy
      @instruction_text.destroy
      @mode_text.destroy
      @logical_size_text.destroy
      @window_size_text.destroy
      @background_texture.destroy
      super
    end
  end

  Game.new.run
end
