require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def init
      GSDL::Events.esc_exits = true
      push(MainScene.new)
    end

    # No assets loaded here via Game class!
  end

  class MainScene < GSDL::Scene
    def load_default_font
      "fonts/PressStart2P.ttf"
    end

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
        text: "Press SPACE to switch\n\nto Per-Scene Asset Loading (Sync)",
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
        Game.switch(MyScene.new)
      end
    end
  end

  class MyScene < GSDL::Scene
    @sprite : GSDL::Sprite?

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures : Array(Tuple(String, String))
      [{"palm_tree", "gfx/palm-tree.png"}]
    end

    def init
      @sprite = GSDL::Sprite.new("palm_tree", x: Game.width // 2, y: Game.height // 2, origin: {0.5_f32, 0.5_f32})
    end

    def draw(draw : GSDL::Draw)
      @sprite.try &.draw(draw)

      text = GSDL::Text.new(
        text: "Scene-specific asset\n\n(palm tree) loaded synchronously",
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

  Game.new("Per-Scene Asset Loading (Sync)", 800, 600).run
end
