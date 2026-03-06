require "../src/game_sdl"

module TileMapEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "TMX TileMap Example", width: WIDTH, height: HEIGHT)
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
      [{"map", "data/maps/map.tmx"}]
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @tile_map : GSDL::TileMap

    def initialize
      super(:start)

      @tile_map = GSDL::TileMapManager.get("map")
      @tile_map.z_index = -5
    end

    def draw(draw : GSDL::Draw)
      @tile_map.draw(draw)
    end
  end

  Game.new.run
end
