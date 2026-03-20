require "../src/game_sdl"

module MultiLayerMapEx
  WIDTH = 800
  HEIGHT = 640

  class Game < GSDL::Game
    def initialize
      super(title: "Tile Map Example", width: WIDTH, height: HEIGHT)
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MapScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [
        {"tiles", "gfx/tiles.png"},
        {"barrel", "gfx/barrel.png"},
        {"palm-tree", "gfx/palm-tree.png"},
      ]
    end

    def load_tile_maps
      # tile map supports both .json and .tmx for now
      [{"map", "data/maps/map.json"}]
    end
  end

  class MapScene < GSDL::Scene
    @tile_map : GSDL::TileMap
    @bg_visible : Bool = true
    @fg_visible : Bool = true
    @objs_visible : Bool = true

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
        @tile_map.set_layer_visibility("Foreground Tiles", @fg_visible)
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::O)
        @objs_visible = !@objs_visible
        @tile_map.set_layer_visibility("Objects", @objs_visible)
      end
    end

    def draw(draw : GSDL::Draw)
      @tile_map.draw(draw)

      font = GSDL::Font.default(16_f32)
      text = "Press 'B' to toggle Background\nPress 'F' to toggle Foreground\nPress 'O' to toggle Objects"
      draw.text(GSDL::Text.new(font: font, text: text, x: 16, y: 16, z_index: 99))

      # Demonstrate independent layer rendering
      # @tile_map.draw_layer(draw, "Foreground")
    end
  end

  Game.new.run
end
