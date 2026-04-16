require "../src/game_sdl"

module PauseEx
  class Game < GSDL::Game
    def initialize
      super(title: "Pause Example")
    end

    def init
      GSDL::Events.esc_exits = false
      GSDL::Game.push(MainScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class CustomPauseScene < GSDL::Scene
    @menu : GSDL::Menu
    @title : GSDL::Text
    @background : GSDL::Box

    def initialize
      super(:custom_pause)
      @z_index = 2000

      @title = GSDL::Text.new(
        text: "CUSTOM PAUSE",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32 - 100,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Gold,
        scale: {2_f32, 2_f32},
        z_index: @z_index
      )
      @title.draw_relative_to_camera = false

      items = [{:resume, "Resume"}, {:settings, "Settings"}, {:credits, "Credits"}, {:quit, "Quit"}]
      @menu = GSDL::Menu.new(
        is_selected: ->(x : GSDL::Num, y : GSDL::Num, w : GSDL::Num, h : GSDL::Num) {
          GSDL::Keys.just_pressed?([GSDL::Keys::Space, GSDL::Keys::Return])
        },
        is_next: -> { GSDL::Keys.just_pressed?([GSDL::Keys::S, GSDL::Keys::Down]) },
        is_previous: -> { GSDL::Keys.just_pressed?([GSDL::Keys::W, GSDL::Keys::Up]) },
        items: items,
        x: GSDL::Game.width // 2,
        y: GSDL::Game.height // 2,
        origin: {0.5_f32, 0.5_f32},
        on_select: ->(id : Symbol) {
          if id == :resume
            GSDL::Game.paused = false
          elsif id == :quit
            GSDL::Game.quit!
          end
          nil
        },
        separation: 16,
        default_text_color: GSDL::Color::Orange,
        selected_text_color: ->(index : Int32) { GSDL::Color::White },
        z_index: @z_index,
        draw_relative_to_camera: false
      )
      @background = GSDL::Box.new(
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32,
        width: Game.width / 1.5_f32,
        height: Game.height / 1.5_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color.new(64, 64, 64, 192),
        z_index: @z_index
      )
      @background.draw_relative_to_camera = false
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        GSDL::Game.paused = false
        return
      end
      @menu.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @background.draw(draw)
      @title.draw(draw)
      @menu.draw(draw)
    end
  end

  class MainScene < GSDL::Scene
    @text : GSDL::Text
    @rotation : Float32 = 0_f32

    def initialize
      super(:main)
      @text = GSDL::Text.new(
        text: "GAME RUNNING\n\nPress ESC to Pause",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Lime,
        align: GSDL::Font::Align::Center
      )
      self.pause_scene = CustomPauseScene.new
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        GSDL::Game.paused = true
      end

      @rotation += 100 * dt
      @text.scale = {1_f32 + Math.sin(@rotation * 0.05_f32) * 0.2_f32, 1_f32 + Math.sin(@rotation * 0.05_f32) * 0.2_f32}
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
