require "../src/game_sdl"

module AsyncSceneLoadingEx
  class Game < GSDL::Game
    def initialize
      super(title: "Async Scene Loading Example")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MenuScene.new)
    end

    def check_scenes
      s = scene
      if s.name == :menu && s.as(MenuScene).start_game?
        switch_async(MainScene)
      end
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class MenuScene < GSDL::Scene
    getter? start_game = false
    @text : GSDL::Text

    def initialize
      super(:menu)
      @text = GSDL::Text.new(
        text: "Dynamic Scene Loading\n\nPress SPACE to Start",
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

  # A custom loading scene
  class CustomLoadingScene(T) < GSDL::LoadingSceneBase
    @text : GSDL::Text
    @next_scene_class : T.class
    @data : GSDL::SwitchData?

    def next_scene_class : GSDL::Scene.class; @next_scene_class; end

    def initialize(@next_scene_class : T.class, @data : GSDL::SwitchData? = nil)
      super(:custom_loading)
      @text = GSDL::Text.new(
        text: "CUSTOM LOADING...",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Gold
      )
    end

    def update(dt : Float32)
      loader = GSDL::Game.instance.loader
      if loader.complete?
        GSDL::Game.switch(T.new, @data)
      end
    end

    def draw(draw : GSDL::Draw)
      loader = GSDL::Game.instance.loader
      progress = loader.progress.percentage

      # Draw a simple progress bar
      bar_w = 400_f32
      bar_h = 20_f32
      x = (GSDL::Game.width - bar_w) / 2_f32
      y = GSDL::Game.height / 2_f32 + 40_f32

      draw.rect_outline(GSDL::FRect.new(x, y, bar_w, bar_h), GSDL::Color::White)
      draw.rect_fill(GSDL::FRect.new(x + 2, y + 2, (bar_w - 4) * (progress / 100.0_f32), bar_h - 4), GSDL::Color::Gold)

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

    # Override the default loading scene for this specific scene
    def self.loading_scene_class(target_scene_class : T.class) : GSDL::LoadingSceneBase forall T
      CustomLoadingScene(T).new(target_scene_class)
    end

    @ship : GSDL::Sprite

    def initialize
      super(:main)

      @ship = GSDL::Sprite.new(key: "ship", origin: {0.5_f32, 0.5_f32})
      @ship.center(width: GSDL::Game.width, height: GSDL::Game.height)

      @text = GSDL::Text.new(
        text: "Main Scene Loaded with Custom Loader!",
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
