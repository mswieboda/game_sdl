require "../src/game_sdl"

module FontStressEx
  WIDTH = 800
  HEIGHT = 600
  TEXT_COUNT = 100

  class Game < GSDL::Game
    def initialize
      super(title: "Font Performance Stress Test", width: 1280, height: 1024)
    end

    def init
      GSDL::Events.esc_exits = true
      self.target_fps = 60
      # Enable performance monitoring
      self.performance_monitoring_enabled = true
      GSDL::Game.push(StressScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class StressScene < GSDL::Scene
    @text = [] of GSDL::TextBeta
    @timer : GSDL::Timer

    def initialize
      super(:stress)
      @timer = GSDL::Timer.new(3.seconds)
      @timer.start

      font_path = "./assets/fonts/PressStart2P.ttf"
      font_size : Float32 = 16_f32
      font_atlas = GSDL::FontAtlas.new(font_path, font_size)
      @text << GSDL::TextBeta.new(
        font_atlas: font_atlas,
        font_atlas_outline: font_atlas, # TODO: temporary until TextStyle impl
        text: "hello! from the dark recesses of evil!\nYOU WON'T CATCH ME\nTHIS TIME FIEND,\nnot now, not ever.\nHear that, punk?",
        x: Game.width // 2,
        y: Game.height // 2,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color.new(g: 255, a: 64) # GSDL::Color::Lime
      )

      rng = Random.new(42)
      TEXT_COUNT.times do
        x = rng.rand(Game.width).to_f32
        y = rng.rand(Game.height).to_f32

        text = if rng.rand > 0.5
          GSDL::TextBeta.new(
            font_atlas: font_atlas,
            font_atlas_outline: font_atlas, # TODO: temporary until TextStyle impl
            text: "This is a testing string, blah!",
            x: x,
            y: y,
            origin: {0.5_f32, 0.5_f32},
            color: GSDL::Color::DarkRed
          )
        else
          GSDL::TextBeta.new(
            font_atlas: font_atlas,
            font_atlas_outline: font_atlas, # TODO: temporary until TextStyle impl
            text: "hello! from the dark recesses of evil!",
            x: x,
            y: y,
            origin: {0.5_f32, 0.5_f32},
            color: GSDL::Color::Lime
          )
        end

        # 25% of entities get an alpha change
        if rng.rand < 0.25
          color = text.color

          case rng.rand(3)
          when 0 # 50% alpha
            text.color = GSDL::Color.new(r: color.r, g: color.g, b: color.b, a: 128)
          when 1 # 75% alpha
            text.color = GSDL::Color.new(r: color.r, g: color.g, b: color.b, a: 191)
          when 2 # 25% alpha
            text.color = GSDL::Color.new(r: color.r, g: color.g, b: color.b, a: 64)
          end
        end

        @text << text
      end

      # # Add Performance HUD
      # h = GSDL::HUD.new
      # h << GSDL::HUDPerformance.new(
      #   anchor: GSDL::Anchor::TopLeft,
      #   offset_x: 32,
      #   offset_y: 32,
      #   color: GSDL::Color::Yellow,
      #   align: GSDL::Font::Align::Left
      # )
      # self.hud = h
    end

    def update(dt : Float32)
      if @timer.done?
        GSDL::Game.quit!
        return
      end

      super(dt)
    end

    def draw_camera_view(draw : GSDL::Draw)
      # draw.color = GSDL::Color::Blue
      # draw.clear
      GSDL::Box.new(x: 300, y: 300, width: 300, height: 300, color: GSDL::Color::Blue, z_index: -100).draw(draw)

      @text.each(&.draw(draw))
    end
  end

  Game.new.run
end
