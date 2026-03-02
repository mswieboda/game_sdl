require "../src/game_sdl"

module AsyncSceneLoadingEx
  class Game < GSDL::Game
    def initialize
      super(title: "Async Scene Loading Example", width: 800, height: 600)
    end

    def init
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      # Start with a menu that will then async load the main scene
      @scene = MenuScene.new
    end

    def check_scenes
      case current_scene = scene
      when MenuScene
        if current_scene.start_game?
          # Dynamic async switch!
          switch_async(MainScene)
        end
      end
    end
  end

  class MenuScene < GSDL::Scene
    getter? start_game = false
    @text : GSDL::Text

    def initialize
      super(:menu)
      @text = GSDL::Text.new(
        text: "Dynamic Scene Loading

Press SPACE to Start",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White,
        align: GSDL::Font::Align::Center
      )
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        @start_game = true
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
    end
  end

  class MainScene < GSDL::Scene
    # Define what this scene needs BEFORE it's instantiated
    def self.manifest : Array(GSDL::Loader::AssetTask)
      [
        GSDL::Loader::AssetTask.new(:Texture, "ship", "gfx/ship.png"),
        GSDL::Loader::AssetTask.new(:Texture, "coin", "gfx/coin.png"),
        GSDL::Loader::AssetTask.new(:Audio, "ding", "sfx/ding.wav")
      ]
    end

    @ship : GSDL::Sprite

    def initialize
      super(:main)
      @ship = GSDL::Sprite.new(key: "ship", origin: {0.5_f32, 0.5_f32})
      @ship.center(width: GSDL::Game.width, height: GSDL::Game.height)
      
      @text = GSDL::Text.new(
        text: "Main Scene Loaded Dynamically!",
        x: GSDL::Game.width / 2_f32,
        y: 50,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Lime
      )
    end

    def update(dt : Float32)
      @ship.rotation += 100 * dt
      
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        GSDL::AudioManager.get("ding").play
      end
    end

    def draw(draw : GSDL::Draw)
      @ship.draw(draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
