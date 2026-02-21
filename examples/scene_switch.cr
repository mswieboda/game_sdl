require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias Num = GSDL::Num

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Scene Switch Ex", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      # NOTE: this is the default, but differnt the other examples
      # so wanted to point it out here
      GSDL::Events.esc_exits = false
      @scene_manager = SceneManager.new
    end

    def load_fonts
      GSDL::FontManager.load_default("fonts/PressStart2P.ttf")
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = StartMenu.new
    end

    def check_scenes
      case current_scene = scene
      when StartMenu
        if current_scene.start_game?
          switch(MainScene.new)
        elsif current_scene.exit?
          @exit = true
        end
      when MainScene
        if current_scene.exit?
          switch(StartMenu.new)
        end
      end
    end
  end

  class StartMenu < GSDL::Scene
    getter? start_game = false

    @menu : GSDL::Menu

    # We need to explicitly allow setting @exit if we want to use it as a signal
    def exit!
      @exit = true
    end

    def initialize
      super(:start_menu)

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
        x: WIDTH // 2,
        y: HEIGHT // 2,
        origin: {0.5_f32, 0.5_f32},
        on_select: ->(id : Symbol) {
          if id == :start
            @start_game = true
          else
            exit!
          end
          nil
        }
      )
    end

    def update(dt : Float32)
      @menu.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @menu.draw(draw)
    end
  end

  class MainScene < GSDL::Scene
    @text : GSDL::Text

    # We need to explicitly allow setting @exit if we want to use it as a signal
    def exit!
      @exit = true
    end

    def initialize
      super(:main_scene)
      @text = GSDL::Text.new(
        text: "Esc to go back to main menu",
        x: WIDTH // 2,
        y: HEIGHT // 2,
        origin: {0.5_f32, 0.5_f32},
        align: GSDL::Font::Align::Center
      )
    end

    def update(dt : Float32)
      exit! if Keys.just_pressed?(Keys::Escape)
      @text.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
