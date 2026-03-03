require "../src/game_sdl"

module PlatformerAdvancedEx
  alias Keys = GSDL::Keys
  alias Input = GSDL::Input

  class Game < GSDL::Game
    def initialize
      super(title: "Platformer Advanced Example", width: 800, height: 640)
    end

    def init
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_textures
      [
        {"player", "gfx/skeleton.png"},
        {"tiles", "gfx/tiles.png"}
      ]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
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
      @use_gravity = true

      # Enable advanced features
      self.max_jumps = 2
      self.can_wall_jump = true
      self.can_dash = true
      self.can_crouch = true

      add("idle", [0], 8)
      add("walk", (1..6).to_a, 8)
      add("jump", [17, 18, 19], 8, loops: false)
      add("crouch", [10], 8)
    end

    def move_speed : GSDL::Num; SPEED; end
    def jump_impulse : GSDL::Num; JUMP_IMPULSE; end

    def collision_bounding_box : GSDL::FRect
      # Shrink box if crouching
      if crouching?
        GSDL::FRect.new(x: 8_f32, y: 32_f32, w: 16_f32, h: 32_f32)
      else
        GSDL::FRect.new(x: 8_f32, y: 16_f32, w: 16_f32, h: 48_f32)
      end
    end

    def update(dt : Float32, collidables : Array(GSDL::Collidable), tile_map : GSDL::TileMap?, world_bounds : GSDL::FRect)
      platformer_update(dt, collidables: collidables, tile_map: tile_map, world_bounds: world_bounds)

      # animation
      dx = 0
      dx = -1 if Input.action?(:left)
      dx = 1 if Input.action?(:right)

      if crouching?
        play("crouch")
      elsif !grounded?
        play("jump") unless playing?("jump")
      elsif dx != 0
        play("walk") unless playing?("walk")
      else
        play("idle")
      end

      super(dt)
    end

    def draw(draw : GSDL::Draw, camera : GSDL::Camera? = nil)
      # Visual feedback for dashing
      current_tint = dashing? ? GSDL::Color::Cyan : nil

      # Visual feedback for wall sliding
      if wall_sliding?
        current_tint = GSDL::Color::Yellow
      end

      draw_x_offset = 0_f32
      draw_y_offset = 0_f32

      old_tint = self.tint
      self.tint = current_tint
      super(draw, camera: camera, flip_horizontal: direction.left?)
      self.tint = old_tint
    end
  end

  class Block < GSDL::Sprite
    def initialize(x, y, w, h)
      super(key: "tiles", x: x, y: y)
      # Use a solid tile from the tileset
      @source_rect = GSDL::FRect.new(x: 0, y: 0, w: 32, h: 32)
      self.scale = {w / 32.0_f32, h / 32.0_f32}
    end
  end

  class StartScene < GSDL::Scene
    @player : Player
    @blocks : Array(GSDL::Collidable)
    @bounds : GSDL::FRect
    @info_text : GSDL::Text

    def initialize
      super(:start)
      Input.set(:jump) { GSDL::Keys.just_pressed?([GSDL::Keys::W, GSDL::Keys::Up, GSDL::Keys::Space]) }
      Input.set(:left) { GSDL::Keys.pressed?([GSDL::Keys::A, GSDL::Keys::Left]) }
      Input.set(:right) { GSDL::Keys.pressed?([GSDL::Keys::D, GSDL::Keys::Right]) }
      Input.set(:crouch) { GSDL::Keys.pressed?([GSDL::Keys::S, GSDL::Keys::Down]) }
      Input.set(:dash) { GSDL::Keys.just_pressed?([GSDL::Keys::LShift, GSDL::Keys::RShift]) }

      @player = Player.new(key: "player", width: 32, height: 64)
      @player.x = 100
      @player.y = 100

      @blocks = [] of GSDL::Collidable
      # Add some floating blocks
      @blocks << Block.new(200, 400, 200, 32)
      @blocks << Block.new(500, 300, 100, 32)
      @blocks << Block.new(100, 500, 600, 32) # floor

      # Add vertical walls for wall sliding
      @blocks << Block.new(50, 100, 32, 400)
      @blocks << Block.new(718, 100, 32, 400)

      # World bounds
      @bounds = GSDL::FRect.new(0, 0, Game.width, Game.height)

      @info_text = GSDL::Text.new(
        text: "ARROWS/WASD: Move/Jump/Crouch
SHIFT: Dash
Space: Double Jump
Walls: Wall Slide/Jump",
        x: Game.width / 2_f32,
        y: 20,
        origin: {0.5_f32, 0_f32},
        color: GSDL::Color::White,
        font: GSDL::Font.default.copy.tap { |f| f.size = 12 }
      )
    end

    def update(dt : Float32)
      @player.update(dt, @blocks, nil, @bounds)
    end

    def draw(draw : GSDL::Draw)
      @blocks.each do |b|
        if b.is_a?(GSDL::Sprite)
          b.draw(draw)
        end
      end

      @player.draw(draw)
      @info_text.draw(draw)

      # Debug: draw player collision box
      box = @player.collision_box
      draw.rect_outline(box, GSDL::Color::Lime, z_index: 10)
    end
  end

  Game.new.run
end
