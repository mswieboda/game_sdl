require "../src/game_sdl"

module ObliquePerspectiveEx
  alias Keys = GSDL::Keys
  alias Input = GSDL::Input

  class Game < GSDL::Game
    def initialize
      super(title: "3/4 Oblique Perspective & Depth Sorting Example")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(ObliqueScene.new)
    end

    def load_textures
      [
        {"player", "gfx/top_down_player.png"},
        {"barrel", "gfx/barrel.png"},
        {"palm_tree", "gfx/palm-tree.png"}
      ]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  # A base class for world objects that support depth
  class WorldObject < GSDL::Sprite
    include GSDL::Oblique

    def initialize(key, x, y, origin = {0.5_f32, 1.0_f32}) # Bottom-center origin for better ground placement
      super(key: key, x: x, y: y, origin: origin)
    end

    def update(dt : Float32)
      update_oblique
      super(dt)
    end
  end

  class Player < GSDL::AnimatedSprite
    include GSDL::TopDownController
    include GSDL::Oblique

    property move_speed : GSDL::Num = 160_f32
    def grid_size : GSDL::Num; 32; end

    # Jump state
    @jumping = false
    @jump_time = 0_f32
    @jump_duration = 0.6_f32
    @jump_height = 48_f32

    def initialize
      # We use 0.5, 1.0 (bottom center) as origin so 'y' is the ground contact point,
      # and player is kind of in middle of grid, with a shadow below
      super(key: "player", width: 24, height: 40, origin: {0.5_f32, 1.0_f32})

      # Row-based animations for 8-directional movement (mirrored for left)
      fps_walk = 8
      add("walk_up", [0, *(12..17)], fps: fps_walk, loops: true)
      add("walk_up_right", [1, *(18..23)], fps: fps_walk, loops: true)
      add("walk_right", [2, *(24..29)], fps: fps_walk, loops: true)
      add("walk_down_right", [3, *(30..35)], fps: fps_walk, loops: true)
      add("walk_down", [4, *(36..41)], fps: fps_walk, loops: true)

      # mirrored versions
      add("walk_down_left", [3, *(30..35)], fps: fps_walk, loops: true)
      add("walk_left", [2, *(24..29)], fps: fps_walk, loops: true)
      add("walk_up_left", [1, *(18..23)], fps: fps_walk, loops: true)

      add("idle_up", [0], fps: fps_walk, loops: true)
      add("idle_up_right", [1], fps: fps_walk, loops: true)
      add("idle_right", [2], fps: fps_walk, loops: true)
      add("idle_down_right", [3], fps: fps_walk, loops: true)
      add("idle_down", [4], fps: fps_walk, loops: true)

      # mirrored versions
      add("idle_down_left", [3], fps: fps_walk, loops: true)
      add("idle_left", [2], fps: fps_walk, loops: true)
      add("idle_up_left", [1], fps: fps_walk, loops: true)

      @directional_mode = DirectionalMode::EightWay

      play("idle_down")
    end

    def update(dt : Float32)
      update_oblique
      top_down_update(dt)

      # Handle Jumping
      if Input.action?(:jump)
        if !@jumping
          @jumping = true
          @jump_time = 0_f32
        end
      end

      if @jumping
        @jump_time += dt
        if @jump_time >= @jump_duration
          @jumping = false
          self.z = 0_f32
        else
          # Parabolic jump curve
          t = @jump_time / @jump_duration
          self.z = (Math.sin(t * Math::PI) * @jump_height).to_f32
        end
      end

      # Animation logic
      prefix = moving? ? "walk" : "idle"
      anim_name = "#{prefix}_#{direction.to_s.underscore}"
      play(anim_name) unless playing?(anim_name)

      super(dt)
    end

    def draw(draw : GSDL::Draw)
      self.flip_h = direction.left? || direction.up_left? || direction.down_left?

      # Draw shadow at ground position (ignoring render_offset_y by using ground_y)
      shadow_w = 20_f32
      shadow_h = 8_f32
      draw.circle_fill(
        x: render_x - shadow_w / 2 + (render_width * origin_x),
        y: ground_y.to_f32 - shadow_h * 2,
        radius: shadow_w / 2,
        color: GSDL::Color.new(0, 0, 0, 100),
        z_index: -1 # Just below sprites
      )

      super(draw)
    end
  end

  class ObliqueScene < GSDL::Scene
    @player : Player
    @objects = [] of WorldObject

    def initialize
      super(:oblique)

      Input.set(:move_left) { Keys.pressed?([Keys::A, Keys::Left]) }
      Input.set(:move_right) { Keys.pressed?([Keys::D, Keys::Right]) }
      Input.set(:move_up) { Keys.pressed?([Keys::W, Keys::Up]) }
      Input.set(:move_down) { Keys.pressed?([Keys::S, Keys::Down]) }
      Input.set(:jump) { Keys.pressed?(Keys::Space) }

      @player = Player.new
      @player.x = 400
      @player.y = 300

      h = GSDL::HUD.new

      # Top Left: Score (Data Bound)
      h << GSDL::HUDText.new(
        text: "3/4 Oblique Perspective:\n\nWASD to move, SPACE to jump",
        anchor: GSDL::Anchor::TopLeft,
        offset_x: 16,
        offset_y: 16,
        color: GSDL::Color::White
      )
      self.hud = h

      add_child(@player)

      # Add some static objects
      @objects << WorldObject.new("barrel", 300, 250)
      @objects << WorldObject.new("barrel", 340, 260)
      @objects << WorldObject.new("palm_tree", 500, 200)
      @objects << WorldObject.new("palm_tree", 200, 400)

      @objects.each { |obj| add_child(obj) }
    end

    def update(dt : Float32)
      super(dt)
      camera.look_at(@player)
      camera.update(dt)
    end

    def draw(draw : GSDL::Draw)
      draw_floor(draw)
      super(draw)
    end

    def draw_floor(draw : GSDL::Draw)
      grid_size = 32
      start_x = ((camera.x / grid_size).to_i - 1) * grid_size
      start_y = ((camera.y / grid_size).to_i - 1) * grid_size
      end_x = start_x + Game.width + grid_size * 2
      end_y = start_y + Game.height + grid_size * 2

      (start_x..end_x).step(grid_size) do |x|
        (start_y..end_y).step(grid_size) do |y|
          color = ((x / grid_size).to_i + (y / grid_size).to_i).abs % 2 == 0 ? GSDL.gray(40) : GSDL.gray(50)
          draw.rect_fill(
            rect: GSDL::FRect.new(
              x.to_f32 - camera.x,
              y.to_f32 - camera.y,
              grid_size.to_f32,
              grid_size.to_f32
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
