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

    def load_textures
      [{"tiles", "gfx/tiles.png"}]
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
      # This will load assets/gfx/map.tmx if it exists, otherwise it might fail
      # if it's not found. We created it earlier.
      @tile_map = GSDL::TileMap.from_tiled_file("assets/gfx/map.tmx")
      @tile_map.z_index = -5
    end

    def draw(draw : GSDL::Draw)
      @tile_map.draw(draw)
    end
  end

  Game.new.run
end
