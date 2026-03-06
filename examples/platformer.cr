require "../src/game_sdl"

module PlatformerEx
  alias Keys = GSDL::Keys
  alias Input = GSDL::Input

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Platformer Example", width: WIDTH, height: HEIGHT)
    end

    def init
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_textures
      [
        {"player", "gfx/skeleton.png"},
        {"barrel", "gfx/barrel.png"},
        {"palm-tree", "gfx/palm-tree.png"},
        {"coin", "gfx/coin.png"},
        {"tiles", "gfx/tiles.png"}
      ]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_audio
      [{"coin_audio", "sfx/ding.wav"}]
    end

    def load_tile_maps
      [{"map", "data/maps/map.json"}]
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = StartScene.new
    end
  end

  class Player < GSDL::AnimatedSprite
    include GSDL::PlatformerController

    JUMP_IMPULSE = -512_f32
    SPEED = 192_f32

    def initialize(key, width, height)
      super(key: key, width: width, height: height)

      # turns gravity on from PlatformerController / TileMapCollidable
      @use_gravity = true

      # adds animations for AnimatedSprite
      add("idle", [0], 8)
      add("walk", (1..6).to_a, 8)
      add("jump", [17, 18, 19], 8, loops: false)
    end

    # Required by PlatformerController
    def move_speed : GSDL::Num; SPEED; end
    def jump_impulse : GSDL::Num; JUMP_IMPULSE; end

    # custom collision box, because of sprite whitespace
    def collision_bounding_box : GSDL::FRect
      GSDL::FRect.new(x: 8_f32, y: 16_f32, w: 16_f32, h: 48_f32)
    end

    def update(dt : Float32, tile_map : GSDL::TileMap, collidables : Array(GSDL::Collidable), world_bounds : GSDL::FRect)
      platformer_update(dt, tile_map: tile_map, collidables: collidables, world_bounds: world_bounds)

      # animation from movement changes
      dx = 0
      dx = -1 if GSDL::Input.action?(:left)
      dx = 1 if GSDL::Input.action?(:right)

      if !grounded?
        play("jump") unless playing?("jump")
      elsif dx != 0
        play("walk") unless playing?("walk")
      else
        play("idle")
      end

      # calls AnimatedSprite#update for animation playback
      super(dt)
    end

    def draw(draw : GSDL::Draw, camera : GSDL::Camera? = nil)
      super(draw, camera: camera, flip_horizontal: direction.left?)
    end
  end

  class Coin < GSDL::AnimatedSprite
    def initialize(x, y)
      super(key: "coin", width: 32, height: 32, x: x, y: y)

      @z_index = 1
      add("idle", [0, 1, 2, 3, 4, 3, 2, 1], 8, loops: true)
      play("idle")
    end
  end

  class CustomPlatform < GSDL::Sprite
    def initialize(x, y, w, h)
      super(key: "tiles", x: x, y: y)

      @z_index = 1

      # Use a solid tile from the tileset
      @source_rect = GSDL::FRect.new(x: 0, y: 0, w: 32, h: 32)
      self.scale = {w / 32.0_f32, h / 32.0_f32}
    end
  end

  class StartScene < GSDL::Scene
    TILE_SIZE = 32

    @tile_map : GSDL::TileMap
    @player : Player
    @camera : GSDL::Camera
    @coins : Array(GSDL::AnimatedSprite)
    @coin_audio : GSDL::Audio
    @collidables : Array(GSDL::Collidable)
    @coin_text : GSDL::Text
    @info_text : GSDL::Text

    property? debug = false

    def initialize
      super(:start)

      # set up input actions, per scene, or even in your scene manager, for the whole game
      Input.set(:jump) { GSDL::Keys.just_pressed?([GSDL::Keys::W, GSDL::Keys::Up, GSDL::Keys::Space]) }
      Input.set(:left) { GSDL::Keys.pressed?([GSDL::Keys::A, GSDL::Keys::Left]) }
      Input.set(:right) { GSDL::Keys.pressed?([GSDL::Keys::D, GSDL::Keys::Right]) }
      Input.set(:debug) { GSDL::Keys.just_pressed?(GSDL::Keys::Tab) }

      # Load the map from a Tiled JSON file
      # NOTE: after exporting a Tiled file to JSON, you'll need to add a
      # "solid_tiles" array to the "tilesets" info, like:
      # "solid_tiles": [1, 2, 3, 8, 10, 11, 12, 17]
      # so that we know which tiles are solid and have collisions
      # and which are just background
      @tile_map = GSDL::TileMapManager.get("map")

      @camera = GSDL::Camera.new(WIDTH, HEIGHT)
      @camera.type = GSDL::Camera::Type::CenterOnTarget

      # player
      @player = Player.new(key: "player", width: 32, height: 64)
      # Set map z_index to -1 so layers are at -1, 0, 1.
      # Player at 1 will be above Ground and Objects, but below Foreground (1).
      @tile_map.z_index = -1
      @player.z_index = 1

      # Spawn player at Tiled object location if available
      if spawn = @tile_map.get_objects_by_type("PlayerStart").first?
        @player.x = spawn.x
        @player.y = spawn.y
      else
        @player.center(width: WIDTH, height: HEIGHT - 300)
      end

      @coin_audio = GSDL::AudioManager.get("coin_audio")
      @coins = [] of GSDL::AnimatedSprite

      spots = [{64, 64}, {320, 320}, {640, 512}, {640, 256}, {256, 256}]

      5.times.to_a do |i|
        x, y = spot = spots[i]
        coin = GSDL::AnimatedSprite.new(key: "coin", width: 32, height: 32, x: x, y: y)
        coin.z_index = 1
        coin.add("idle", [0, 1, 2, 3, 4, 3, 2, 1], 8, loops: true)
        coin.play("idle")
        @coins << coin
      end

      GSDL::Data.set("coins_collected", 0)
      @coin_text = GSDL::Text.new(
        text: "Coins: 0",
        x: WIDTH - 32,
        y: 32,
        origin: {1.0_f32, 0_f32},
        z_index: 5,
        color: GSDL::Color::Gold
      )

      # Add a floating sprite block, instead of tiles
      @collidables = [] of GSDL::Collidable
      @collidables << CustomPlatform.new(x: 160, y: 384, w: 160, h: 16)

      small_font = GSDL::Font.default.copy
      small_font.size = 12

      @info_text = GSDL::Text.new(
        font: small_font,
        text: "TAB to toggle debug",
        x: WIDTH / 2_f32,
        y: 16,
        z_index: 5,
        origin: {0.5_f32, 0_f32},
        color: GSDL::Color::Lime
      )

      # World bounds: slightly larger than the tile map to see them working
      @bounds = GSDL::FRect.new(-16, -16, @tile_map.width + 32, @tile_map.height + 32)
    end

    def update(dt : Float32)
      @debug = !@debug if Input.action?(:debug)

      @coins.each(&.update(dt))

      @player.update(dt, @tile_map, @collidables, @bounds)

      @coins.each do |coin|
        if @player.collides?(coin)
          @coin_audio.play
          @coins.delete(coin)
          GSDL::Data.increment("coins_collected")
          @coin_text.text = "Coins: #{GSDL::Data.get("coins_collected")}"
        end
      end

      # camera follows player
      @camera.look_at(@player.x, @player.y)
      @camera.update(dt)
    end

    def draw(draw : GSDL::Draw)
      # Draw bounds in red
      bounds_camera = GSDL::FRect.new(x: @bounds.x - @camera.x, y: @bounds.y - @camera.y, w: @bounds.w, h: @bounds.h)
      draw.rect_outline(bounds_camera, GSDL::Color::Red, z_index: 1)

      @tile_map.draw(draw, @camera)

      @collidables.each do |b|
        # could loop through Collidables and draw each kind separately
        if b.is_a?(GSDL::Sprite)
          b.draw(draw, @camera)
        end
      end

      @coins.each(&.draw(draw, @camera))
      @player.draw(draw, @camera)
      @coin_text.draw(draw)
      @info_text.draw(draw)

      return unless debug?
      # Debug: Draw collision boxes
      # Player collision box
      player_box = @player.collision_box
      draw.rect_outline(
        rect: GSDL::FRect.new(
          x: player_box.x - @camera.x,
          y: player_box.y - @camera.y,
          w: player_box.w,
          h: player_box.h
        ),
        color: GSDL::Color::Lime,
        z_index: 100
      )

      # Coins collision boxes
      @coins.each do |coin|
        coin_box = coin.collision_box
        draw.rect_outline(
          rect: GSDL::FRect.new(
            x: coin_box.x - @camera.x,
            y: coin_box.y - @camera.y,
            w: coin_box.w,
            h: coin_box.h
          ),
          color: GSDL::Color::Gold,
          z_index: 100
        )
      end
    end
  end

  Game.new.run
end
