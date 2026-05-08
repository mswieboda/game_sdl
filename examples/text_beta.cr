require "../src/game_sdl"

class MainScene < GSDL::Scene
  @text : GSDL::TextBeta

  def initialize
    super(:main)

    font_path = "./assets/fonts/PressStart2P.ttf"
    font_size : Float32 = 16_f32
    font_atlas = GSDL::FontAtlas.new(font_path, font_size)
    @text = GSDL::TextBeta.new(
      font_atlas: font_atlas,
      text: "jumping quickly over lazy dogs\nis good exercise!\nbatt1 batt2 batt3",
      x: FontAtlasExample.width // 2,
      y: 300,
      origin: {0.5_f32, 0.5_f32},
      h_align: GSDL::HorizontalAlign::Center,
      v_align: GSDL::VerticalAlign::Center,
      line_spacing: 1.2_f32,
      typing: GSDL::TextBeta::Typing::Word,
      # rotation: 30,
      # character_spacing: 3,
      # width: 300,
      # height: 300,
    )
  end

  def draw_screen_overlay(draw : GSDL::Draw)
    box_bg = GSDL::Box.new(
      x: @text.x,
      y: @text.y,
      width: @text.width,
      height: @text.height,
      origin: @text.origin,
      scale: @text.scale,
      color: GSDL::Color.gray(64),
      z_index: @text.z_index - 1,
    )

    circle_xy = GSDL::Circle.new(
      x: @text.x,
      y: @text.y,
      origin: {0.5_f32, 0.5_f32},
      radius: 16,
      color: GSDL::Color::Magenta,
      z_index: @text.z_index + 1,
    )

    box_bg.draw(draw)
    @text.draw(draw)
    # circle_xy.draw(draw)
  end

  def update(dt : Float32)
    super

    if GSDL::Keys.pressed?(GSDL::Keys::Escape)
      GSDL::Game.quit!
    end

    # reset width
    if GSDL::Keys.just_pressed?(GSDL::Keys::Tab)
      @text.width = nil
    end

    # reset height
    if GSDL::Keys.just_pressed?(GSDL::Keys::Return)
      @text.height = nil
    end

    # reset width & height
    if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
      @text.width = nil
      @text.height = nil
    end

    # width decrease
    if GSDL::Keys.just_pressed?(GSDL::Keys::A) || GSDL::Keys.pressed?(GSDL::Keys::Left)
      @text.width -= 1
    end

    # width increase
    if GSDL::Keys.just_pressed?(GSDL::Keys::D) || GSDL::Keys.pressed?(GSDL::Keys::Right)
      @text.width += 1
    end

    # height decrease
    if GSDL::Keys.just_pressed?(GSDL::Keys::W) || GSDL::Keys.pressed?(GSDL::Keys::Up)
      @text.height -= 1
    end

    # height increase
    if GSDL::Keys.just_pressed?(GSDL::Keys::S) || GSDL::Keys.pressed?(GSDL::Keys::Down)
      @text.height += 1
    end
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
