require "../src/game_sdl"

class MainScene < GSDL::Scene
  @font : GSDL::FontAtlas

  def initialize
    super(:main)

    # Use a common font size for testing
    @font = GSDL::FontAtlas.new("./assets/fonts/PressStart2P.ttf", 32.0_f32)
    @font_small = GSDL::FontAtlas.new("./assets/fonts/PressStart2P.ttf", 16.0_f32)
  end

  def draw_text_beta(
    draw : GSDL::Draw,
    text : String,
    x : GSDL::Num,
    y : GSDL::Num,
    h_align : GSDL::HorizontalAlign = GSDL::HorizontalAlign::Left,
    line_spacing : GSDL::Num = 1.2_f32,
    origin = {0_f32, 0_f32},
    color = GSDL::Color::White,
    width : GSDL::Num? = nil,
    height : GSDL::Num? = nil,
    z_index : Int32 = 0,
  )
    text = GSDL::TextBeta.new(
      text: text,
      x: x,
      y: y,
      h_align: h_align,
      line_spacing: line_spacing,
      origin: origin,
      color: color,
      width: width,
      height: height,
      z_index: z_index,
    )

    box_bg = GSDL::Box.new(
      x: x,
      y: y,
      width: text.width,
      height: text.height,
      origin: origin,
      color: GSDL::Color.gray(64),
      z_index: z_index,
    )

    circle_xy = GSDL::Circle.new(
      x: x,
      y: y,
      origin: {0.5_f32, 0.5_f32},
      radius: 8,
      z_index: z_index + 1,
    )

    box_bg.draw(draw)
    text.draw(draw)
    circle_xy.draw(draw)
  end

  def draw_screen_overlay(draw : GSDL::Draw)
    draw_text_beta(
      draw: draw,
      text: "jumping quickly over lazy dogs\nis good exercise!",
      x: 16,
      y: 128,
      h_align: GSDL::HorizontalAlign::Center,
      # line_spacing: 1_f32,
      # width: 900,
    )
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
