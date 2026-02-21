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
      super
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_textures
      GSDL::TextureManager.load("player", "gfx/skeleton.png")
      GSDL::TextureManager.load("coin", "gfx/coin.png")
      GSDL::TextureManager.load("tiles", "gfx/tiles.png")
    end

    def load_fonts
      GSDL::FontManager.load_default("fonts/PressStart2P.ttf")
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

    JUMP_IMPULSE = -512_f32
    SPEED = 192_f32

    getter? facing_left

    def initialize(key, width, height)
      super(key: key, width: width, height: height)

      # for flipping the texture horizontally from last movement direction
      @facing_left = false

      # turns gravity on from TileMapCollidable
      @use_gravity = true

      # adds animations for AnimatedSprite
      add("idle", [0], 8)
      add("walk", (1..6).to_a, 8)
      add("jump", [17, 18, 19], 8, loops: false)
    end

    # custom collision box, because of sprite whitespace
    def collision_bounding_box : GSDL::FRect
      GSDL::FRect.new(x: 8_f32, y: 16_f32, w: 16_f32, h: 48_f32)
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
      # can use Input[:jump] or Input.action?(:jump)
      jump(JUMP_IMPULSE) if grounded? && Input.action?(:jump)

      # physics and collision handling
      move_and_collide(dt, tile_map)

      # animation from movement changes
      update_animation(dx)
    end

    def dx_from_movement : Int32
      dx = 0
      dx = -1 if Input.action?(:left)
      dx = 1 if Input.action?(:right)
      dx
    end

    def update_animation(dx : Int32)
      @facing_left = dx < 0 if dx != 0

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

      # player
      @player = Player.new(key: "player", width: 32, height: 64)

      # TODO: find a way to include player start tile from map.json
      @player.center(width: WIDTH, height: HEIGHT - 300)

      @coin_audio = GSDL::AudioManager.get("coin_audio")
      @coins = [] of GSDL::AnimatedSprite

      spots = [{64, 64}, {320, 320}, {640, 512}, {640, 256}, {256, 256}]

      5.times.to_a do |i|
        x, y = spot = spots[i]
        coin = GSDL::AnimatedSprite.new(key: "coin", width: 32, height: 32, x: x, y: y)
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
        color: GSDL::Color::Gold
      )

      small_font = GSDL::Font.default.copy
      small_font.size = 12

      @info_text = GSDL::Text.new(
        font: small_font,
        text: "TAB to toggle debug",
        x: WIDTH / 2_f32,
        y: 16,
        origin: {0.5_f32, 0_f32},
        color: GSDL::Color::Lime
      )
    end

    def update(dt : Float32)
      @debug = !@debug if Input.action?(:debug)

      @coins.each(&.update(dt))

      @player.update(dt, @tile_map)

      @coins.each do |coin|
        if @player.collides?(coin)
          @coin_audio.play
          @coins.delete(coin)
          GSDL::Data.increment("coins_collected")
          @coin_text.text = "Coins: #{GSDL::Data.get("coins_collected")}"
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
      @coin_text.draw(draw)
      @info_text.draw(draw)

      return unless debug?
      # Debug: Draw collision boxes
      # Player collision box
      player_box = @player.collision_box
      draw.rect_outline(
        rect: GSDL::FRect.new(
          x: player_box.x - @camera_x,
          y: player_box.y - @camera_y,
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
            x: coin_box.x - @camera_x,
            y: coin_box.y - @camera_y,
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
