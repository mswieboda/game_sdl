require "../src/game_sdl"

module AsyncLoadingEx
  class Game < GSDL::Game
    def initialize
      super(title: "Async Loading Example", width: 800, height: 600)
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
        text: "Loading Assets...",
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

      # Queue assets
      loader = GSDL::Game.instance.loader
      loader.add_texture("ship", "gfx/ship.png")
      loader.add_texture("coin", "gfx/coin.png")
      loader.add_texture("tiles", "gfx/tiles.png")
      loader.add_audio("race_car", "sfx/race_car.wav")

      # 200.times do |i|
      #   loader.add_texture("ship_#{i}", "gfx/ship.png")
      #   loader.add_texture("coin_#{i}", "gfx/coin.png")
      #   loader.add_texture("tiles_#{i}", "gfx/tiles.png")
      #   loader.add_audio("race_car_#{i}", "sfx/race_car.wav")
      # end

      loader.add_font("default", "fonts/PressStart2P.ttf", 16_f32)
      
      # Start loading
      loader.start_async
    end

    def update(dt : Float32)
      loader = GSDL::Game.instance.loader
      progress = loader.progress
      # puts ">>> loader progress: #{progress.percentage} %"
      @progress_text.text = "#{progress.percentage.to_i}%"
      
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
      @ship = GSDL::Sprite.new("ship", source_rect: GSDL::FRect.new(x: 0, y: 0, w: 128), origin: {0.5_f32, 0.5_f32})
      @ship.center(width: GSDL::Game.width, height: GSDL::Game.height)
      
      @text = GSDL::Text.new(
        text: "Assets Loaded Successfully!",
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
