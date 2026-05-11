require "../src/game_sdl"

module MultiLayerMapEx
  WIDTH = 800
  HEIGHT = 640

  class Game < GSDL::Game
    def initialize
      super(title: "Tile Map Example")
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

      hud = GSDL::HUD.new
      font = GSDL::Font.default(16_f32)
      text = "Press 'B' to toggle Background\nPress 'F' to toggle Foreground\nPress 'O' to toggle Objects"
      hud << GSDL::HUDText.new(text: text, offset_x: 16, offset_y: 16)
      self.hud = hud
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

    def draw_camera_view(draw : GSDL::Draw)
      @tile_map.draw(draw)
    end
  end

  Game.new.run
end
