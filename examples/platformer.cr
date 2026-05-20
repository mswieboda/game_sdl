require "../src/game_sdl"

module PlatformerEx
  alias Keys = GSDL::Keys
  alias Input = GSDL::Input

  class Game < GSDL::Game
    def initialize
      super(title: "Platformer Example", logical_width: 480, logical_height: 320)
    end

    def init
      GSDL::Events.esc_exits = true
      self.target_fps = 60
      GSDL::Game.push(StartScene.new)
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

    def load_fonts
      [
        {"fonts/PressStart2P.ttf", 12, 0},
        {"fonts/PressStart2P.ttf", 6, 0}
      ]
    end

    def load_audio
      [{"coin_audio", "sfx/ding.wav"}]
    end

    def load_tile_maps
      [{"map", "data/maps/map.json"}]
    end
  end

  class Player < GSDL::AnimatedSprite
    include GSDL::PlatformerController

    JUMP_IMPULSE = -512_f32
    SPEED = 192_f32

    def initialize(key, width, height)
      super(key: key, width: width, height: height, origin: {0.5_f32, 0_f32})

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

    def update(dt : Float32)
      # No need to pass tile_map, collidables, or world_bounds!
      # They are automatically fetched from StartScene's CollisionSpace.
      platformer_update(dt)

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

    def draw(draw : GSDL::Draw)
      self.flip_h = direction.left?
      super(draw)
    end
  end

  class Coin < GSDL::AnimatedSprite
    def initialize(x, y)
      super(key: "coin", width: 32, height: 32, x: x, y: y)

      @z_index = 1
      self.solid = false
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
    include GSDL::SceneCollisions # Opt-in to automated collision management

    TILE_SIZE = 32

    @tile_map : GSDL::TileMap
    @player : Player
    @coins : Array(GSDL::AnimatedSprite)
    @coin_audio : GSDL::Audio

    property? debug = false

    def initialize
      super(:start)

      # set up input actions
      Input.set(:jump) { GSDL::Keys.just_pressed?([GSDL::Keys::W, GSDL::Keys::Up, GSDL::Keys::Space]) }
      Input.set(:left) { GSDL::Keys.pressed?([GSDL::Keys::A, GSDL::Keys::Left]) }
      Input.set(:right) { GSDL::Keys.pressed?([GSDL::Keys::D, GSDL::Keys::Right]) }
      Input.set(:debug) { GSDL::Keys.just_pressed?(GSDL::Keys::Tab) }

      @tile_map = GSDL::TileMapManager.get("map")
      camera.type = GSDL::Camera::Type::CenterOnTarget

      # Register the tile map with the collision space
      collision_space.tile_map = @tile_map

      # World bounds: slightly larger than the tile map
      collision_space.space_bounds = GSDL::FRect.new(-16, -16, @tile_map.width + 32, @tile_map.height + 32)

      # player
      @player = Player.new(key: "player", width: 32, height: 64)
      @tile_map.z_index = -1
      @player.z_index = 1

      # Spawn player
      if spawn = @tile_map.get_objects_by_type("PlayerStart").first?
        @player.x = spawn.x
        @player.y = spawn.y
      else
        @player.center(width: Game.width, height: Game.height - 300)
      end
      add_child(@player) # Auto-registered as a Collidable

      @coin_audio = GSDL::AudioManager.get("coin_audio")
      @coins = [] of GSDL::AnimatedSprite

      spots = [{64, 64}, {320, 320}, {640, 512}, {640, 256}, {256, 256}]

      5.times.to_a do |i|
        x, y = spots[i]
        coin = Coin.new(x, y)
        @coins << coin
        add_child(coin) # Auto-registered as a Collidable
      end

      # Add a floating sprite block
      # add_child automatically registers it with collision_space because CustomPlatform (Sprite) is Collidable
      add_child(CustomPlatform.new(x: 160, y: 384, w: 160, h: 16))

      # HUD
      hud = GSDL::HUD.new

      GSDL::Data.set("coins_collected", 0)
      hud << GSDL::HUDText.new(
        font_size: 12,
        text_data_template: "Coins: {coins_collected}",
        anchor: GSDL::Anchor::TopLeft,
        offset_x: 8,
        offset_y: 8,
        color: GSDL::Color::Gold
      )

      hud << GSDL::HUDText.new(
        font_size: 6,
        text: "TAB\nto debug",
        anchor: GSDL::Anchor::TopCenter,
        h_align: GSDL::HorizontalAlign::Center,
        origin: {0.5_f32, 0_f32},
        offset_y: 8,
        color: GSDL::Color::Lime
      )

      GSDL::Data.set("fps", 0)
      hud << GSDL::HUDText.new(
        font_size: 6,
        text_data_template: "FPS: {fps}",
        anchor: GSDL::Anchor::TopRight,
        origin: {1_f32, 0_f32},
        offset_x: 8,
        offset_y: 8,
        color: GSDL::Color::Lime
      )

      self.hud = hud
    end

    def update(dt : Float32)
      @debug = !@debug if Input.action?(:debug)

      super(dt) # Updates hud and all children (player, coins, platforms)

      @coins.each do |coin|
        if @player.collides?(coin)
          @coin_audio.play
          @coins.delete(coin)
          remove_child(coin) # Auto-unregistered from collision_space
          GSDL::Data.increment("coins_collected")
        end
      end

      # camera follows player
      camera.look_at(@player.x, @player.y)
      camera.update(dt)

      GSDL::Data.set("fps", GSDL::Game.fps)
    end

    def draw_camera_view(draw : GSDL::Draw)
      # Draw bounds in red
      if bounds = collision_space.space_bounds
        draw.rect_outline(bounds, GSDL::Color::Red, z_index: 1)
      end

      @tile_map.draw(draw)

      super(draw) # Draws all children (player, coins, platforms)

      return unless debug?
      # Debug: Draw collision boxes
      player_box = @player.collision_box
      draw.rect_outline(
        rect: GSDL::FRect.new(
          x: player_box.x,
          y: player_box.y,
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
            x: coin_box.x,
            y: coin_box.y,
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
