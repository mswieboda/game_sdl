require "../src/game_sdl"

class MainScene < GSDL::Scene
  @font : GSDL::FontAtlas

  def initialize
    super(:main)

    # Use a common font size for testing
    @font = GSDL::FontAtlas.new("./assets/fonts/PressStart2P.ttf", 32.0_f32)
    @font_small = GSDL::FontAtlas.new("./assets/fonts/PressStart2P.ttf", 16.0_f32)
  end

  def draw_screen_overlay(draw : GSDL::Draw)
    # Test basic rendering and different colors
    @font.draw_text("GSDL Font Atlas Rendering", 40, 40, GSDL::Color::White)
    GSDL::Circle.new(x: 40, y: 40, origin: {0.5_f32, 0.5_f32}, radius: 8, z_index: 0).draw(draw)

    # @font.draw_text("High Performance & Batched", 40, 90, GSDL::Color::Yellow)
    GSDL::TextBeta.new(text: "TextBeta rendering", x: 40, y: 90, color: GSDL::Color::Yellow).draw(draw)
    GSDL::Circle.new(x: 40, y: 90, origin: {0.5_f32, 0.5_f32}, radius: 8, z_index: 0).draw(draw)

    # Baseline check: 'j', 'g', 'p', 'q', 'y' have descenders
    # @font.draw_text("jumping quickly over lazy dogs", 40, 160, GSDL::Color::Cyan)
    GSDL::TextBeta.new(text: "jumping quickly over lazy dogs", x: 40, y: 160, color: GSDL::Color::Cyan).draw(draw)
    GSDL::Circle.new(x: 40, y: 160, origin: {0.5_f32, 0.5_f32}, radius: 8, z_index: 0).draw(draw)

    # Numbers and symbols
    # @font.draw_text("0123456789 !@#$%^&*()_+", 40, 230, GSDL::Color::Red)
    GSDL::TextBeta.new(text: "0123456789 !@#$%^&*()_+", x: 40, y: 230, color: GSDL::Color::Red).draw(draw)
    GSDL::Circle.new(x: 40, y: 230, origin: {0.5_f32, 0.5_f32}, radius: 8, z_index: 0).draw(draw)

    # Alpha transparency test
    @font.draw_text("Alpha Blending Test", 40, 300, GSDL::Color.new(0, 255, 0, 128))
    GSDL::Circle.new(x: 40, y: 300, origin: {0.5_f32, 0.5_f32}, radius: 8, z_index: 0).draw(draw)

    # Smaller text for comparison
    # Note: We'd need another FontAtlas for a different size, or we could scale this one
    # but standard atlas usage is one per size for crispness.
    @font_small.draw_text("Smaller text size", 40, 400, GSDL::Color::LimeGreen)
    GSDL::Circle.new(x: 40, y: 400, origin: {0.5_f32, 0.5_f32}, radius: 8, z_index: 0).draw(draw)

    @font.draw_text("Press ESC to Quit", 40, 500, GSDL::Color::Gray)
    GSDL::Circle.new(x: 40, y: 500, origin: {0.5_f32, 0.5_f32}, radius: 8, z_index: 0).draw(draw)
  end

  def update(dt : Float32)
    super
    if GSDL::Keys.pressed?(GSDL::Keys::Escape)
      GSDL::Game.quit!
    end
  end

  def destroy
    @font.try(&.destroy)
  end
end

class FontAtlasExample < GSDL::Game
  def init
    push(MainScene.new)
  end
end

# Set target_fps to 60 for consistency
game = FontAtlasExample.new(title: "Font Atlas Example", width: 1280, height: 1024)
game.target_fps = 60
game.run
