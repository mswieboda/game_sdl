require "../src/game_sdl"

module SceneStackEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Scene Stack Example")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MainScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class MainScene < GSDL::Scene
    @box_x = 0_f32

    def initialize
      super(:main)
    end

    def update(dt : Float32)
      @box_x += 100_f32 * dt
      @box_x = 0_f32 if @box_x > WIDTH

      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        GSDL::Game.push(OverlayScene.new)
      end
    end

    def draw(draw : GSDL::Draw)
      draw.rect_fill(GSDL::FRect.new(@box_x, 200, 50, 50), GSDL::Color::Blue)
      text = GSDL::Text.new(text: "Main Scene running. Press SPACE to push Overlay.")
      text.x = 10
      text.y = 10
      text.draw(draw)
    end
  end

  class OverlayScene < GSDL::Scene
    def initialize
      super(:overlay)
      self.transparent = true
      self.update_underlying = false # Pause main scene
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Return)
        GSDL::Game.pop
      end
    end

    def draw(draw : GSDL::Draw)
      # Dim background
      draw.rect_fill(GSDL::FRect.new(0, 0, WIDTH, HEIGHT), GSDL::Color.new(0, 0, 0, 150), z_index: 100)
      text = GSDL::Text.new(text: "OVERLAY (Transparent & Pausing Underlying)\nPress ENTER to pop.", z_index: 101)
      text.x = 100
      text.y = 100
      text.draw(draw)
    end
  end

  Game.new.run
end
