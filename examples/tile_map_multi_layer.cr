require "../src/game_sdl"

module MultiLayerMapEx
  WIDTH = 800
  HEIGHT = 640

  class Game < GSDL::Game
    def initialize
      super(title: "Tile Ma Multi-Layer Example", width: WIDTH, height: HEIGHT)
    end

    def init
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [{"tiles", "gfx/tiles.png"}]
    end

    def load_tile_maps
      [{"map", "data/maps/multi_layer_map.json"}]
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = MapScene.new
    end
  end

  class MapScene < GSDL::Scene
    @tile_map : GSDL::TileMap
    @bg_visible : Bool = true
    @fg_visible : Bool = true

    def initialize
      super(:map)

      @tile_map = GSDL::TileMapManager.get("map")
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::B)
        @bg_visible = !@bg_visible
        @tile_map.set_layer_visibility("Background", @bg_visible)
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::F)
        @fg_visible = !@fg_visible
        @tile_map.set_layer_visibility("Foreground", @fg_visible)
      end
    end

    def draw(draw : GSDL::Draw)
      @tile_map.draw(draw)

      font = GSDL::Font.default(16_f32)
      draw.text(GSDL::Text.new(font: font, text: "Press 'B' to toggle Background", x: 10, y: 10))
      draw.text(GSDL::Text.new(font: font, text: "Press 'F' to toggle Foreground", x: 10, y: 35))

      # Demonstrate independent layer rendering
      # draw.text(GSDL::Text.new(font: font, text: "Foreground only:", x: 10, y: 60))
      # @tile_map.draw_layer(draw, "Foreground")
    end
  end

  Game.new.run
end


