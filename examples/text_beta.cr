require "../src/game_sdl"

class MainScene < GSDL::Scene
  @text : GSDL::TextBeta
  @font_texture : GSDL::Texture
  @outline_texture : GSDL::Texture

  def initialize
    super(:main)

    outline = 4
    font_path = "./assets/fonts/Roboto-Regular.ttf"
    # font_path = "./assets/fonts/PressStart2P.ttf"
    # font_path = "./assets/fonts/Electrolize-Regular.ttf"
    font_atlas = GSDL::FontAtlas.new(font_path, size: 32)
    font_atlas_outline = GSDL::FontAtlas.new(font_path, size: 32, outline: outline)

    @font_texture = font_atlas.texture
    @outline_texture = font_atlas_outline.texture

    @text = GSDL::TextBeta.new(
      font_atlas: font_atlas,
      font_atlas_outline: font_atlas_outline,
      text: "jumping quickly over lazy dogs\nis good exercise!\nbatty1 batty2 batty3",
      x: FontAtlasExample.width // 2,
      y: FontAtlasExample.height // 2,
      origin: {0.5_f32, 0.5_f32},
      h_align: GSDL::HorizontalAlign::Center,
      v_align: GSDL::VerticalAlign::Center,
      line_spacing: 2,
      typing: GSDL::TextBeta::Typing::Word,
      shadow: {2, 2},
      shadow_color: GSDL::Color::Magenta,
      outline: outline,
      # outline_color: GSDL::Color::Magenta,
      # rotation: 30,
      character_spacing: 2,
      width: 300,
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
      rotation: @text.rotation,
      color: GSDL::Color.gray(64),
      z_index: @text.z_index - 1,
    )

    circle_xy = GSDL::Circle.new(
      x: @text.x,
      y: @text.y,
      origin: {0.5_f32, 0.5_f32},
      radius: 16,
      color: GSDL::Color::Magenta,
      z_index: @text.z_index_max + 1,
    )

    box_bg.draw(draw)
    @text.draw(draw)
    circle_xy.draw(draw)
  end

  # def draw_screen_overlay(draw : GSDL::Draw)
  #   draw.texture(
  #     texture: @outline_texture,
  #     z_index: 1
  #   )
  #   draw.texture(
  #     texture: @font_texture,
  #     tint: GSDL::Color::Magenta,
  #     z_index: 5
  #   )
  # end

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
    if GSDL::Keys.just_pressed?(GSDL::Keys::S) || GSDL::Keys.pressed?(GSDL::Keys::Down)
      @text.height -= 1
    end

    # height increase
    if GSDL::Keys.just_pressed?(GSDL::Keys::W) || GSDL::Keys.pressed?(GSDL::Keys::Up)
      @text.height += 1
    end

    # rotation decrease
    if GSDL::Keys.pressed?(GSDL::Keys::Q)
      @text.rotation -= 1
    end

    # rotation increase
    if GSDL::Keys.pressed?(GSDL::Keys::E)
      @text.rotation += 1
    end
  end
end

class FontAtlasExample < GSDL::Game
  def init
    push(MainScene.new)
  end
end

# Set target_fps to 60 for consistency
game = FontAtlasExample.new(title: "Font Atlas Example", width: 640, height: 640, high_pixel_density: true)
# game = FontAtlasExample.new(title: "Font Atlas Example", logical_width: 1280, logical_height: 1024, width: 640, height: 512, high_pixel_density: true)
# game = FontAtlasExample.new(title: "Font Atlas Example", logical_width: 640, logical_height: 512, fullscreen: true, high_pixel_density: true)
game.target_fps = 60
game.run
