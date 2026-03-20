require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def init
      GSDL::Events.esc_exits = true
      push(MainScene.new)
    end

    # needed for default loading screen
    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class MainScene < GSDL::Scene
    def draw(draw : GSDL::Draw)
      text = GSDL::Text.new(
        text: "Main Scene",
        x: Game.width // 2,
        y: Game.height // 2,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White
      )
      text.draw(draw)

      text2 = GSDL::Text.new(
        text: "Press SPACE to switch\n\nto Per-Scene Asset Loading (Async)",
        x: Game.width // 2,
        y: Game.height - 64,
        align: GSDL::Font::Align::Center,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Cyan
      )
      text2.draw(draw)
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        Game.switch_async(MyScene)
      end
    end
  end

  class MyScene < GSDL::Scene
    @sprite : GSDL::Sprite?
    @sprite2 : GSDL::Sprite?
    @sprite3 : GSDL::Sprite?

    def load_textures : Array(Tuple(String, String))
      [
        {"palm_tree", "gfx/palm-tree.png"},
        {"barrel", "gfx/barrel.png"},
        {"skeleton", "gfx/skeleton.png"}
      ]
    end

    # used to make the loader take longer, but they are unused
    def load_audio
      600.times.to_a.map do |i|
        {"audio_#{i}", "sfx/race_car.wav"}
      end
    end

    def init
      @sprite = GSDL::Sprite.new("palm_tree", x: Game.width // 2, y: Game.height // 2, origin: {0.5_f32, 0.5_f32})
      @sprite2 = GSDL::Sprite.new("barrel", x: Game.width // 2 - 100, y: Game.height // 2, origin: {0.5_f32, 0.5_f32})
      @sprite3 = GSDL::Sprite.new("skeleton", x: Game.width // 2 + 100, y: Game.height // 2, origin: {0.5_f32, 0.5_f32})
    end

    def draw(draw : GSDL::Draw)
      @sprite.try &.draw(draw)
      @sprite2.try &.draw(draw)
      @sprite3.try &.draw(draw)

      text = GSDL::Text.new(
        text: "Scene-specific assets loaded\n\nasynchronously via LoadingScene",
        x: Game.width // 2,
        y: 32,
        align: GSDL::Font::Align::Center,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White
      )
      text.draw(draw)

      text2 = GSDL::Text.new(
        text: "Press SPACE to switch\n\nback to Main Scene",
        x: Game.width // 2,
        y: Game.height - 64,
        align: GSDL::Font::Align::Center,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Yellow
      )
      text2.draw(draw)
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        Game.switch(MainScene.new)
      end
    end
  end

  Game.new("Per-Scene Asset Loading (Async)", 800, 600).run
end
