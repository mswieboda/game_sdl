require "../src/game_sdl"

module PlatformerEx
  alias Keys = GSDL::Keys

  WIDTH = 800
  HEIGHT = 600
  TILE_SIZE = 32

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
    getter start

    def initialize
      super

      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @tile_map : GSDL::TileMap
    @camera_x : Int32 = 0
    @camera_y : Int32 = 0
    @sprite : GSDL::AnimatedSprite

    GRAVITY = 980_f32
    JUMP_IMPULSE = -500_f32

    # player physics
    @velocity_y = 0_f32
    @on_ground = false

    def initialize
      super(:start)

      # Create a tileset from tiles.png, assuming it's one TILE_SIZE x TILE_SIZE tile
      # first_gid = 1, as 0 is usually reserved for empty tiles
      texture = GSDL::TextureManager.get("tiles")
      tileset = GSDL::Tileset.new(texture, TILE_SIZE, TILE_SIZE, 1)
      tileset.solid_tiles = [0]

      @tile_map = GSDL::TileMap.new(TILE_SIZE, TILE_SIZE)
      @tile_map.add_tileset("tiles", tileset)

      @sprite = GSDL::AnimatedSprite.new("player", 32, 64)
      @sprite.center(WIDTH, HEIGHT - 300)
      @sprite.add("idle", [0], 8)
      @sprite.add("walk", (1..6).to_a, 8)
      @sprite.add("jump", [17, 18, 19], 8, loops: false)
      @sprite.play("idle")

      # Manually define some map data
      # 0 = empty, other are tiles from tiles.png asset
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
    end

    def update(dt : Float32)
      @sprite.update(dt)

      speed = 150 * dt
      dx = 0

      if Keys.pressed?([Keys::A, Keys::Left])
        dx -= speed
      end

      if Keys.pressed?([Keys::D, Keys::Right])
        dx += speed
      end

      if @on_ground && Keys.just_pressed?([Keys::W, Keys::Up])
        @velocity_y = JUMP_IMPULSE
        @on_ground = false
        @sprite.play("jump") unless @sprite.playing?("jump")
      end

      # Apply gravity
      @velocity_y += GRAVITY * dt

      # Vertical collision
      @on_ground = false

      # desired y position
      dy = @velocity_y * dt

      # next position
      next_y = @sprite.y + dy
      collided_y = false

      # check for collision
      if @velocity_y > 0 # moving down
        # check the bottom of the sprite
        if @tile_map.solid_at?(@sprite.x.to_i, (next_y + @sprite.height).to_i) || @tile_map.solid_at?((@sprite.x + @sprite.width - 1).to_i, (next_y + @sprite.height).to_i)
          # collision detected
          @velocity_y = 0
          @sprite.y = (((next_y + @sprite.height) / TILE_SIZE).to_i * TILE_SIZE - @sprite.height).to_f32
          @on_ground = true
          collided_y = true
        end
      elsif @velocity_y < 0 # moving up
        # check the top of the sprite
        if @tile_map.solid_at?(@sprite.x.to_i, next_y.to_i) || @tile_map.solid_at?((@sprite.x + @sprite.width - 1).to_i, next_y.to_i)
          # collision detected
          @velocity_y = 0
          @sprite.y = (((next_y / TILE_SIZE).to_i + 1) * TILE_SIZE).to_f32
          collided_y = true
        end
      end

      if !collided_y
        @sprite.y = next_y
      end

      # Horizontal collision
      next_x = @sprite.x + dx
      collided_x = false

      if dx > 0 # moving right
        if @tile_map.solid_at?((next_x + @sprite.width).to_i, @sprite.y.to_i) ||
           @tile_map.solid_at?((next_x + @sprite.width).to_i, (@sprite.y + @sprite.height / 2).to_i) ||
           @tile_map.solid_at?((next_x + @sprite.width).to_i, (@sprite.y + @sprite.height - 1).to_i)
          @sprite.x = (((next_x + @sprite.width) / TILE_SIZE).to_i * TILE_SIZE - @sprite.width).to_f32
          collided_x = true
        end
      elsif dx < 0 # moving left
        if @tile_map.solid_at?(next_x.to_i, @sprite.y.to_i) ||
           @tile_map.solid_at?(next_x.to_i, (@sprite.y + @sprite.height / 2).to_i) ||
           @tile_map.solid_at?(next_x.to_i, (@sprite.y + @sprite.height - 1).to_i)
          @sprite.x = ((((next_x / TILE_SIZE).to_i + 1) * TILE_SIZE)).to_f32
          collided_x = true
        end
      end

      if !collided_x
        @sprite.x = next_x
      end

      if dx != 0 && !collided_x
        @sprite.play("walk") unless @sprite.playing?("walk") || !@on_ground
      elsif @on_ground
        @sprite.play("idle")
      end

      @camera_x = (@sprite.x - WIDTH / 2).to_i
      @camera_y = (@sprite.y - HEIGHT / 2).to_i
    end

    def draw(renderer : GSDL::Renderer)
      @tile_map.draw(renderer, @camera_x, @camera_y)
      @sprite.draw(renderer, camera_x: @camera_x.to_f32, camera_y: @camera_y.to_f32)
    end
  end

  # Main entry point for the example
  game = Game.new
  game.run
end