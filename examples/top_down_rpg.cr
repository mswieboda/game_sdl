require "../src/game_sdl"

module TopDownRPGEx
  alias Keys = GSDL::Keys
  alias Input = GSDL::Input

  class Game < GSDL::Game
    def initialize
      super(title: "Top Down RPG Controller Example", width: 800, height: 640)
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(RPGScene.new)
        end

    def load_textures
      [{"player", "gfx/top_down_player.png"}]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class Player < GSDL::AnimatedSprite
    include GSDL::TopDownController

    @player_grid_offset = {x: 4, y: -14}

    property move_speed : GSDL::Num = 128_f32
    property grid_size : GSDL::Num = 32_f32

    def initialize
      super(key: "player", width: 24, height: 40, origin: {0.5_f32, 0.5_f32})

      # Animations: idle_down, idle_up, idle_left, idle_right, walk_down, walk_up, walk_left, walk_right
      # Skeleton sheet has 7 frames per row.
      # Row 0: idle? No, let's just use some frames.

      # TODO: fix these frames
      fps_walk = 8
      add("walk_up", [0, *(12..17)], fps: fps_walk, loops: true)
      add("walk_up_right", [1, *(18..23)], fps: fps_walk, loops: true)
      add("walk_right", [2, *(24..29)], fps: fps_walk, loops: true)
      add("walk_down_right", [3, *(30..35)], fps: fps_walk, loops: true)
      add("walk_down", [4, *(36..41)], fps: fps_walk, loops: true)

      # same a _right because we will flip via draw if facing left
      add("walk_down_left", [3, *(30..35)], fps: fps_walk, loops: true)
      add("walk_left", [2, *(24..29)], fps: fps_walk, loops: true)
      add("walk_up_left", [1, *(18..23)], fps: fps_walk, loops: true)

      add("idle_up", [0], fps: fps_walk, loops: true)
      add("idle_up_right", [1], fps: fps_walk, loops: true)
      add("idle_right", [2], fps: fps_walk, loops: true)
      add("idle_down_right", [3], fps: fps_walk, loops: true)
      add("idle_down", [4], fps: fps_walk, loops: true)

      # same a _right because we will flip via draw if facing left
      add("idle_down_left", [3], fps: fps_walk, loops: true)
      add("idle_left", [2], fps: fps_walk, loops: true)
      add("idle_up_left", [1], fps: fps_walk, loops: true)

      play("idle_down")
    end

    def toggle_movement_mode
      @movement_mode = @movement_mode.free_form? ?
        GSDL::TopDownController::MovementMode::GridLocked :
        GSDL::TopDownController::MovementMode::FreeForm

      if @movement_mode.grid_locked?
        snap_to_grid
      else
        # Restore origin to center for free-form movement
        @origin = {0.5_f32, 0.5_f32}
        # Re-center based on current top-left position since we just changed origin
        self.x = self.x + width / 2_f32
        self.y = self.y + height / 2_f32
      end
    end

    def snap_to_grid
      # Calculate nearest grid cell top-left
      # We subtract the half-width/height because currently in freeform the x,y is the center
      current_top_left_x = self.x - (width / 2_f32)
      current_top_left_y = self.y - (height / 2_f32)

      nearest_grid_x = (current_top_left_x / grid_size.to_f32).round * grid_size.to_f32
      nearest_grid_y = (current_top_left_y / grid_size.to_f32).round * grid_size.to_f32

      @origin = {0_f32, 0_f32}
      self.x = nearest_grid_x.to_f32 + @player_grid_offset[:x].to_f32
      self.y = nearest_grid_y.to_f32 + @player_grid_offset[:y].to_f32
    end

    def update(dt : Float32)
      top_down_update(dt)

      # Animation logic based on direction and movement
      prefix = moving? ? "walk" : "idle"
      anim_name = "#{prefix}_#{direction.to_s.underscore}"
      play(anim_name) unless playing?(anim_name)

      super(dt)
    end

    def draw(draw : GSDL::Draw, camera : GSDL::Camera? = nil)
      flip = direction.left? || direction.up_left? || direction.down_left?
      super(draw, camera: camera, flip_horizontal: flip)
    end
  end

  class RPGScene < GSDL::Scene
    @camera : GSDL::Camera
    @player : Player
    @info_text : GSDL::Text
    @mode_text : GSDL::Text

    GRID_SIZE = 32

    def initialize
      super(:rpg)

      Input.set(:move_left) { Keys.pressed?([Keys::A, Keys::Left]) }
      Input.set(:move_right) { Keys.pressed?([Keys::D, Keys::Right]) }
      Input.set(:move_up) { Keys.pressed?([Keys::W, Keys::Up]) }
      Input.set(:move_down) { Keys.pressed?([Keys::S, Keys::Down]) }

      Input.set(:toggle_movement) { Keys.just_pressed?(Keys::One) }
      Input.set(:toggle_directional) { Keys.just_pressed?(Keys::Two) }

      @camera = GSDL::Camera.new(width: Game.width, height: Game.height)
      @player = Player.new
      @player.center(width: Game.width, height: Game.height)

      @info_text = GSDL::Text.new(
        text: "Top Down RPG Controller: WASD/Arrows to move",
        x: 10, y: 10, color: GSDL::Color::White
      )
      @mode_text = GSDL::Text.new(
        text: "1: FreeForm",
        x: 10, y: 40, color: GSDL::Color::White
      )
    end

    def update(dt : Float32)
      if Input.action?(:toggle_directional)
        @player.directional_mode = @player.directional_mode.four_way? ?
          GSDL::TopDownController::DirectionalMode::EightWay :
          GSDL::TopDownController::DirectionalMode::FourWay
      end

      if Input.action?(:toggle_movement)
        @player.toggle_movement_mode
      end

      @player.update(dt)
      @camera.look_at(@player)
      @camera.update(dt)

      text = "1: #{@player.movement_mode}"
      text += " 2: #{@player.directional_mode}" if @player.movement_mode.free_form?
      @mode_text.text = text
    end

    def draw(draw : GSDL::Draw)
      draw_floor(draw)
      @player.draw(draw, @camera)
      @info_text.draw(draw)
      @mode_text.draw(draw)
    end

    def draw_floor(draw : GSDL::Draw)
      # Draw a simple grid
      end_x = Game.width + GRID_SIZE * 2
      end_y = Game.height + GRID_SIZE * 2

      (0..end_x).step(GRID_SIZE) do |x|
        (0..end_y).step(GRID_SIZE) do |y|
          color = ((x / GRID_SIZE).to_i + (y / GRID_SIZE).to_i) % 2 == 0 ? GSDL.gray(64) : GSDL.gray(80)
          draw.rect_fill(
            rect: GSDL::FRect.new(
              x.to_f32 - @camera.x,
              y.to_f32 - @camera.y,
              GRID_SIZE.to_f32,
              GRID_SIZE.to_f32
            ),
            color: color,
            z_index: -10
          )
        end
      end
    end
  end

  Game.new.run
end
