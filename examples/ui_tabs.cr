require "../src/game_sdl"

module TabsExample
  class Game < GSDL::Game
    def initialize
      super(title: "UI Tab Container Example")
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MainScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class MainScene < GSDL::Scene
    @tabs : GSDL::TabContainer
    @content_text : GSDL::Text

    def initialize
      super(:main)

      @tabs = GSDL::TabContainer.new(
        tabs: ["Stats", "Inventory", "Settings"],
        x: 400, y: 300,
        width: 500, height: 400,
        origin: {0.5_f32, 0.5_f32}
      )

      @content_text = GSDL::Text.new(
        text: "Character Stats:\n\nHP: 100/100\nMP: 50/50\nLV: 1",
        x: 400, y: 320,
        origin: {0.5_f32, 0.0_f32}
      )

      @tabs.on_tab_changed = ->(index : Int32) {
        case index
        when 0
          @content_text.text = "Character Stats:\n\nHP: 100/100\nMP: 50/50\nLV: 1"
        when 1
          @content_text.text = "Inventory:\n\n- Wooden Sword\n- Healing Potion x3\n- Old Map"
        when 2
          @content_text.text = "Settings:\n\n- Volume: [#######---]\n- Fullscreen: [X]\n- Difficulty: Normal"
        end
      }
    end

    def update(dt : Float32)
      @tabs.update(dt)
      @content_text.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @tabs.draw(draw)
      @content_text.draw(draw)
    end
  end

  Game.new.run
end
