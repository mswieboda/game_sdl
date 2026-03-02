require "../src/game_sdl"

module AsyncLoadingEx
  AssetTotal = 1000


  class Game < GSDL::Game
    def initialize
      super(title: "Async Loading Stress Test", width: 800, height: 600)
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
      @scene = LoadingScene.new
    end

    def check_scenes
      if scene.is_a?(LoadingScene) && scene.as(LoadingScene).done?
        switch(MainScene.new)
      end
    end
  end

  class LoadingScene < GSDL::Scene
    @text : GSDL::Text
    @progress_text : GSDL::Text
    @done = false

    def initialize
      super(:loading)
      @text = GSDL::Text.new(
        text: "Loading #{AssetTotal} Assets...",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32 - 20,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White
      )
      @progress_text = GSDL::Text.new(
        text: "0%",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32 + 20,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Cyan
      )

      # Queue assets - Stress test with 1000 tasks
      loader = GSDL::Game.instance.loader

      # Mix of textures and audio
      (AssetTotal / 2).to_i.times do |i|
        if i % 2 == 0
          # Reuse same file but with unique key to simulate many textures
          loader.add_texture("ship_#{i}", "gfx/ship.png")
        else
          loader.add_audio("audio_#{i}", "sfx/race_car.wav")
        end
      end
      
      # Start loading with 4 worker threads
      loader.start_async(workers: 4)
    end

    def update(dt : Float32)
      loader = GSDL::Game.instance.loader
      progress = loader.progress

      @progress_text.text = "#{progress.percentage.to_i}% (#{progress.loaded_count}/#{progress.total_count})"
      
      if loader.complete?
        @done = true
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
      @progress_text.draw(draw)
    end

    def done?
      @done
    end
  end

  class MainScene < GSDL::Scene
    @ship : GSDL::Sprite

    def initialize
      super(:main)

      @ship = GSDL::Sprite.new(key: "ship_0", origin: {0.5_f32, 0.5_f32})
      @ship.center(width: GSDL::Game.width, height: GSDL::Game.height)
      
      @text = GSDL::Text.new(
        text: "#{AssetTotal} Assets Loaded Successfully!",
        x: GSDL::Game.width / 2_f32,
        y: 50,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Lime
      )
    end

    def update(dt : Float32)
      @ship.rotation += 100 * dt
    end

    def draw(draw : GSDL::Draw)
      @ship.draw(draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
