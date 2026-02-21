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
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_textures
      GSDL::TextureManager.load("tiles", "gfx/tiles.png")
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
    @camera_x : Int32 = 0
    @camera_y : Int32 = 0

    def initialize
      super(:start)

      # Create a tileset from tiles.png, assuming it's one TILE_SIZE x TILE_SIZE tile
      # first_gid = 1, as 0 is usually reserved for empty tiles
      texture = GSDL::TextureManager.get("tiles")
      tileset = GSDL::Tileset.new(texture, TILE_SIZE, TILE_SIZE, 1)
      tileset.solid_tiles = [1, 10]

      @tile_map = GSDL::TileMap.new(TILE_SIZE, TILE_SIZE)
      @tile_map.add_tileset("tiles", tileset)

      # Manually define some map data
      # 0 = empty, other are tiles from tiles.png asset
      map_data = [
        [9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 9, 5, 5, 9, 9, 9, 9, 9],
        [9, 9, 9, 5, 5, 9, 9, 9, 9, 9],
        [9, 1, 1, 1, 1, 9, 9, 9, 9, 9],
        [1, 1, 1, 1, 1, 1, 1, 9, 9, 9],
        [1, 1, 1, 1, 1, 1, 1, 1, 9, 9],
        [7, 8, 10, 11, 12, 1, 1, 1, 1, 9],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      ]
      @tile_map.load_map_data(map_data)
    end

    def draw(draw : GSDL::Draw)
      @tile_map.draw(draw, @camera_x, @camera_y)
    end
  end

  # Main entry point for the example
  game = Game.new
  game.run
end