require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def initialize
      super(title: "Font Atlas Example", width: 640, height: 640, high_pixel_density: true)
    end

    def init
      self.target_fps = 60
      push(MainScene.new)
    end

    def load_font_atlases
      [
        {"fonts/Roboto-Regular.ttf", 32, 0},
        {"fonts/Roboto-Regular.ttf", 32, 4}
      ]
    end
  end

  class MainScene < GSDL::Scene
    @text : GSDL::TextBeta

    def initialize
      super(:main)

      @text = GSDL::TextBeta.new(
        font: "Roboto-Regular",
        font_size: 32,
        # text: "blah blah blah one two three four",
        text: "jumping quickly over lazy dogs\nis good exercise!\nbatty1 batty2 batty3",
        x: Game.width // 2,
        y: Game.height // 2,
        origin: {0.5_f32, 0.5_f32},
        h_align: GSDL::HorizontalAlign::Center,
        v_align: GSDL::VerticalAlign::Center,
        line_spacing: 2,
        # typing: GSDL::TextBeta::Typing::Word,
        shadow: {2, 2},
        shadow_color: GSDL::Color::Magenta,
        # outline: 4,
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

      # modify text
      if GSDL::Keys.pressed?(GSDL::Keys::T)
        @text.text = "blah blah blah one two three four"
      end
    end
  end

  Game.new.run
end
