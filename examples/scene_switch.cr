require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias Num = GSDL::Num

  class GameEx < GSDL::Game
    def initialize
      super(title: "Scene Switch Ex")
    end

    def init
      GSDL::Events.esc_exits = false
      GSDL::Game.push(StartMenu.new)
    end

    def check_scenes
      s = scene
      if s.name == :start_menu && s.as(StartMenu).start_game?
        switch(MainScene.new)
      elsif s.name == :main_scene && s.exit?
        switch(StartMenu.new)
      end
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_default_font_old
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [{"tiles", "gfx/tiles.png"}]
    end
  end

  class StartMenu < GSDL::Scene
    getter? start_game = false

    @menu : GSDL::Menu

    def initialize
      transition_in = GSDL::FadeTransition.new(
        direction: GSDL::TransitionDirection::In,
        duration: 0.75_f32,
        started: true
      )
      transition_out = GSDL::FadeTransition.new(
        direction: GSDL::TransitionDirection::Out,
        duration: 0.5_f32
      )

      super(name: :start_menu, transition_in: transition_in, transition_out: transition_out)

      items = [
        {:start, "start"},
        {:exit, "exit"}
      ]

      @menu = GSDL::Menu.new(
        is_selected: ->(x : Num, y : Num, w : Num, h : Num) {
          Keys.just_pressed?([Keys::Space, Keys::Return])
        },
        is_next: -> { Keys.just_pressed?([Keys::S, Keys::Down]) },
        is_previous: -> { Keys.just_pressed?([Keys::W, Keys::Up]) },
        items: items,
        x: GameEx.width // 2,
        y: GameEx.height // 2,
        origin: {0.5_f32, 0.5_f32},
        on_select: ->(id : Symbol) {
          if id == :start
            @start_game = true
          else
            transition_out.start
          end
          nil
        }
      )
    end

    def update(dt : Float32)
      if Keys.just_pressed?(Keys::Escape)
        transition_out.start
        return
      end

      @menu.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @menu.draw(draw)
    end
  end

  class MainScene < GSDL::Scene
    @message : GSDL::Message

    def initialize
      transition_in = GSDL::SquareTransition.new(
        direction: GSDL::TransitionDirection::In,
        duration: 1.5_f32,
        grid_size: 16,
        started: true
      )
      transition_out = GSDL::FadeTransition.new(
        direction: GSDL::TransitionDirection::Out,
        duration: 0.5_f32
      )

      super(name: :main_scene, transition_in: transition_in, transition_out: transition_out)

      @message = GSDL::Message.new(
        text: "Esc to go back\nto the main menu\n",
        x: 256,
        y: 128,
        color: GSDL::Color::Magenta,
        align: GSDL::FontOld::Align::Center,
        border_radius: 32
      )

      @sprite = GSDL::Sprite.new(:tiles)
    end

    def update(dt : Float32)
      transition_out.start if Keys.just_pressed?(Keys::Escape)

      @message.update(dt)
    end

    def draw(draw : GSDL::Draw)
      cols = GSDL::Game.width // @sprite.width + 1
      rows = GSDL::Game.height // @sprite.height + 1

      cols.times do |x|
        rows.times do |y|
          @sprite.x = x * @sprite.width
          @sprite.y = y * @sprite.height
          @sprite.draw(draw)
        end
      end

      @message.draw(draw)
    end
  end

  GameEx.new.run
end
