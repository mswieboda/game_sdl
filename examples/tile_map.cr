require "../src/game_sdl"

module TileMapEx
  WIDTH = 800
  HEIGHT = 600
  TILE_SIZE = 32

  class Game < GSDL::Game
    def initialize
      super(title: "TileMap Example", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_textures
      GSDL::TextureManager.load("tiles", "./assets/gfx/tiles.png")
    end
  end

  class SceneManager < GSDL::SceneManager
    getter start

    def initialize
      super

      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @tilemap : GSDL::Gfx::TileMap
    @camera_x : Int32 = 0
    @camera_y : Int32 = 0

    def initialize
      super(:start)

      # Create a tileset from tiles.png, assuming it's one TILE_SIZE x TILE_SIZE tile
      # first_gid = 1, as 0 is usually reserved for empty tiles
      texture = GSDL::TextureManager.get("tiles")
      tileset = GSDL::Gfx::Tileset.new(texture, TILE_SIZE, TILE_SIZE, 1)

      @tilemap = GSDL::Gfx::TileMap.new(TILE_SIZE, TILE_SIZE)
      @tilemap.add_tileset("tiles", tileset)

      # Manually define some map data
      # 0 = empty, other are tiles from tiles.png asset
      map_data = [
        [0, 3, 3, 0, 5, 5, 2, 2, 0, 0],
        [0, 3, 3, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 1, 0, 0, 0, 0, 0, 0],
        [0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
        [0, 2, 2, 0, 0, 1, 1, 0, 0, 0],
        [0, 0, 5, 5, 0, 1, 1, 0, 0, 0],
        [0, 0, 5, 5, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ]
      @tilemap.load_map_data(map_data)
    end

    def draw(renderer : GSDL::Renderer)
      @tilemap.draw(renderer, @camera_x, @camera_y)
    end
  end

  # Main entry point for the example
  game = Game.new
  game.run
end