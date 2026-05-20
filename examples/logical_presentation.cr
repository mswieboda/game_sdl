require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias Text = GSDL::Text

  class Game < GSDL::Game
    @current_mode_index = 0

    def initialize
      super(title: "Logical Presentation Example", width: 800, height: 800, logical_width: 640, logical_height: 480)
    end

    def init
      GSDL::Events.esc_exits = true
      # GSDL::Game.draw.logical_presentation is automatically set in Game#_init to Letterbox
      # when logical_width/height are passed to super()
      @current_mode_index = 2 # LETTERBOX
      GSDL::Game.push(StartScene.new(@current_mode_index))
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class StartScene < GSDL::Scene
    @bg_texture : GSDL::Texture
    @current_mode_index = 0

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

    def initialize(@current_mode_index = 0)
      super(:logical_presentation)

      mode = @presentation_modes[@current_mode_index]
      GSDL::Game.draw.logical_presentation = {GSDL::Game.width, GSDL::Game.height, mode}
      GSDL::Data.set("mode", "#{mode}")

      # Create a checkerboard background surface (fills logical area)
      surface = GSDL::Surface.new(GSDL::Game.width, GSDL::Game.height)

      # Draw checkerboard pattern
      tile_size = 20
      color1 = GSDL.color(50, 50, 50, 255) # Dark gray
      color2 = GSDL.color(150, 150, 150, 255) # Light gray

      (0...GSDL::Game.height).step(tile_size) do |y|
        (0...GSDL::Game.width).step(tile_size) do |x|
          rect = GSDL::Rect.new(x: x, y: y, w: tile_size, h: tile_size)
          if ((x / tile_size) + (y / tile_size)) % 2 == 0
            surface.draw_rect_fill(rect, color1)
          else
            surface.draw_rect_fill(rect, color2)
          end
        end
      end

      @bg_texture = Game.draw.create_texture(surface)

      hud = GSDL::HUD.new
      hud << GSDL::HUDText.new(
        offset_x: 16,
        offset_y: 16,
        text_data_template: "SPACE to change mode\n" \
          "Mode: {mode}\n" \
          "Logical Size: #{Game.width}x#{Game.height}\n" \
          "Window Size: #{Game.window_width}x#{Game.window_height}"
      )
      self.hud = hud
    end

    def update(dt : Float32)
      if Keys.just_pressed?(Keys::Escape)
        @exit = true
        return
      end

      if Keys.just_pressed?(Keys::Space)
        @current_mode_index = (@current_mode_index + 1) % @presentation_modes.size
        mode = @presentation_modes[@current_mode_index]
        GSDL::Game.draw.logical_presentation = {GSDL::Game.width, GSDL::Game.height, mode}
        GSDL::Data.set("mode", "#{mode}")
        puts "Switched logical presentation to: #{mode}"
      end

      super(dt)
    end

    def draw_screen_overlay(draw : GSDL::Draw)
      # Clear with a distinct color to show letterboxing/overscan areas
      draw.color = GSDL::Color::Magenta
      draw.clear

      # Render background, which will be scaled by the logical presentation
      bg_dest_rect = GSDL::FRect.new(w: GSDL::Game.width, h: GSDL::Game.height)
      draw.texture(texture: @bg_texture, dest_rect: bg_dest_rect, draw_immediately: true)

      # Render HUD
      super(draw)
    end

    def destroy
      @bg_texture.destroy
      super
    end
  end

  Game.new.run
end
