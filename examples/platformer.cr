require "../src/game_sdl"

module PlatformerEx
  alias Keys = GSDL::Keys

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Platformer Example", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_textures
      GSDL::TextureManager.load("player", "./assets/gfx/skeleton.png")
      GSDL::TextureManager.load("tiles", "./assets/gfx/tiles.png")
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = StartScene.new
    end
  end

  class Player < GSDL::AnimatedSprite
    include GSDL::TileMapCollidable

    JUMP_IMPULSE = -500.0_f32
    SPEED = 150.0_f32

    getter? facing_left

    def initialize(key, w, h)
      super(key, w, h)

      # for flipping the texture horizontally from last movement direction
      @facing_left = false

      # turns gravity on from TileMapCollidable
      @use_gravity = true


      # adds animations for AnimatedSprite
      add("idle", [0], 8)
      add("walk", (1..6).to_a, 8)
      add("jump", [17, 18, 19], 8, loops: false)
    end

    def update(dt : Float32, tile_map : GSDL::TileMap)
      update_movement(dt, tile_map)

      # calls AnimatedSprite#update for animation playback
      super(dt)
    end

    def update_movement(dt : Float32, tile_map : GSDL::TileMap)
      # horizontal input Handling
      dx = dx_from_movement

      @velocity_x = dx * SPEED

      # jump
      if grounded? && Keys.just_pressed?([Keys::W, Keys::Up])
        jump(JUMP_IMPULSE)
      end

      # physics and collision handling
      move_and_collide(dt, tile_map)

      # animation from movement changes
      update_animation(dx)
    end

    def dx_from_movement : Int32
      # --- Input Handling ---
      dx = 0

      if Keys.pressed?([Keys::A, Keys::Left])
        dx = -1
      end

      if Keys.pressed?([Keys::D, Keys::Right])
        dx = 1
      end

      dx
    end

    def update_animation(dx : Int32)
      # --- Animation ---
      if dx != 0
        @facing_left = dx < 0
      end

      if !grounded?
        play("jump") unless playing?("jump")
      elsif dx != 0
        play("walk") unless playing?("walk")
      else
        play("idle")
      end
    end

    def draw(renderer : GSDL::Renderer, camera_x : Float32, camera_y : Float32)
      super(renderer, camera_x: camera_x, camera_y: camera_y, flip_horizontal: facing_left?)
    end
  end

  class StartScene < GSDL::Scene
    TILE_SIZE = 32

    @tile_map : GSDL::TileMap
    @player : Player
    @camera_x : Int32 = 0
    @camera_y : Int32 = 0

    def initialize
      super(:start)

      # Tileset
      texture = GSDL::TextureManager.get("tiles")
      tileset = GSDL::Tileset.new(texture, TILE_SIZE, TILE_SIZE, 1)
      tileset.solid_tiles = [0]

      # Tilemap
      @tile_map = GSDL::TileMap.new(TILE_SIZE, TILE_SIZE)
      @tile_map.add_tileset("tiles", tileset)
      map_data = [
        [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 5, 5, 5, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 1, 1, 1],
        [9, 9, 5, 5, 5, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [9, 9, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [1, 1, 1, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 1, 1, 1, 1, 9, 9, 9, 9],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 9],
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 9, 9]
      ]
      @tile_map.load_map_data(map_data)

      # Player
      @player = Player.new("player", 32, 64)
      @player.collision_box = SDL3::FRect.new(x: 4_f32, y: 16_f32, w: 24_f32, h: 48_f32)
      @player.center(WIDTH, HEIGHT - 300)
    end

    def update(dt : Float32)
      @player.update(dt, @tile_map)

      # Camera follows player
      @camera_x = (@player.x - WIDTH / 2).to_i
      @camera_y = (@player.y - HEIGHT / 2).to_i
    end

    def draw(renderer : GSDL::Renderer)
      @tile_map.draw(renderer, @camera_x, @camera_y)
      @player.draw(renderer, @camera_x.to_f32, @camera_y.to_f32)
    end
  end

  # Main entry point for the example
  game = Game.new
  game.run
end