require "../src/game_sdl"

class MainScene < GSDL::Scene
  @text : GSDL::TextBeta

  def initialize
    super(:main)

    @text = GSDL::TextBeta.new(
      text: "jumping_ quickly_ over_ lazy_ dogs_\nis_   good_   exercise!_\n\nbatt1_ batt2_ batt3_",
      # text: "jumping quickly over lazy dogs is   good   exercise! batt1 batt2 batt3",
      # text: "jumping",
      # text: "jump",
      # x: 16,
      x: FontAtlasExample.width // 2,
      # x: 300,
      # y: 128,
      y: 300,
      # y: 600,
      # y: FontAtlasExample.height // 2,
      # scale: {2_f32, 2_f32},
      # scale: {3_f32, 3_f32},
      origin: {0.5_f32, 0.5_f32},
      # h_align: GSDL::HorizontalAlign::Center,
      # h_align: GSDL::HorizontalAlign::Right,
      # v_align: GSDL::VerticalAlign::Center,
      # line_spacing: 1_f32,
      line_spacing: 3_f32,
      # width: 300,
      # height: 112,
      height: 300,
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
    circle_xy.draw(draw)
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
