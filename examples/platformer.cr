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
      GSDL::TextureManager.load("player", "gfx/skeleton.png")
      GSDL::TextureManager.load("coin", "gfx/coin.png")
      GSDL::TextureManager.load("tiles", "gfx/tiles.png")
    end

    def load_audio
      GSDL::AudioManager.load("coin_audio", "sfx/ding.wav")
    end

    def load_tile_maps
      GSDL::TileMapManager.load("map", "gfx/map.json")
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

    def draw(draw : GSDL::Draw, camera_x : Float32, camera_y : Float32)
      super(draw, camera_x: camera_x, camera_y: camera_y, flip_horizontal: facing_left?)
    end
  end

  class StartScene < GSDL::Scene
    TILE_SIZE = 32

    @tile_map : GSDL::TileMap
    @player : Player
    @camera_x : Int32 = 0
    @camera_y : Int32 = 0
    @coins : Array(GSDL::AnimatedSprite)
    @coin_audio : GSDL::Audio

    def initialize
      super(:start)

      # Load the map from a Tiled JSON file
      # NOTE: after exporting a Tiled file to JSON, you'll need to add a
      # "solid_tiles" array to the "tilesets" info, like:
      # "solid_tiles": [1, 2, 3, 8, 10, 11, 12, 17]
      # so that we know which tiles are solid and have collisions
      # and which are just background
      @tile_map = GSDL::TileMapManager.get("map")

      # player
      @player = Player.new("player", 32, 64)
      @player.collision_bounding_box = GSDL::FRect.new(x: 8_f32, y: 16_f32, w: 16_f32, h: 48_f32)

      # TODO: find a way to include player start tile from map.json
      @player.center(WIDTH, HEIGHT - 300)

      @coin_audio = GSDL::AudioManager.get("coin_audio")
      @coins = [] of GSDL::AnimatedSprite

      spots = [{64, 64}, {320, 320}, {640, 512}, {640, 256}, {256, 256}]

      5.times.to_a do |i|
        coin = GSDL::AnimatedSprite.new(key: "coin", width: 32, height: 32, x: spots[i][0].to_f32, y: spots[i][1].to_f32)
        coin.add("idle", [0, 1, 2, 3, 4, 3, 2, 1], 8, loops: true)
        coin.play("idle")
        @coins << coin
      end
    end

    def update(dt : Float32)
      @coins.each(&.update(dt))

      @player.update(dt, @tile_map)

      @coins.each do |coin|
        if @player.collides?(coin)
          @coin_audio.play
          @coins.delete(coin)
        end
      end

      # camera follows player
      @camera_x = (@player.x - WIDTH / 2).to_i
      @camera_y = (@player.y - HEIGHT / 2).to_i
    end

    def draw(draw : GSDL::Draw)
      @tile_map.draw(draw, @camera_x, @camera_y)
      @coins.each(&.draw(draw, @camera_x.to_f32, @camera_y.to_f32))
      @player.draw(draw, @camera_x.to_f32, @camera_y.to_f32)
    end
  end

  game = Game.new
  game.run
end
