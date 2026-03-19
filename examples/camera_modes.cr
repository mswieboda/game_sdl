require "../src/game_sdl"

module CameraEx
  alias Keys = GSDL::Keys
  alias Input = GSDL::Input

  class Game < GSDL::Game
    def initialize
      super(title: "Camera Modes Example", width: 800, height: 640)
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(StartScene.new)
        end

    def load_textures
      [{"player", "gfx/skeleton.png"}]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class Player < GSDL::AnimatedSprite
    SPEED = 256_f32

    @velocity_x = 0_f32
    @velocity_y = 0_f32

    def initialize(key, width, height)
      super(key: key, width: width, height: height, origin: {0.5_f32, 0.5_f32})
      add("idle", [0], 8)
      add("walk", (1..6).to_a, 8)
      play("idle")
    end

    def update(dt : Float32, boundary : GSDL::Rect)
      dx = 0_f32
      dy = 0_f32
      dx = -1_f32 if Input.action?(:left)
      dx = 1_f32 if Input.action?(:right)
      dy = -1_f32 if Input.action?(:up)
      dy = 1_f32 if Input.action?(:down)

      @velocity_x = dx * SPEED
      @velocity_y = dy * SPEED

      self.x += @velocity_x * dt
      self.y += @velocity_y * dt

      if dx != 0 || dy != 0
        play("walk")
      else
        play("idle")
      end

      super(dt)
    end
  end

  class StartScene < GSDL::Scene
    @boundary : GSDL::Rect
    @camera : GSDL::Camera
    @player : Player
    @info_text : GSDL::Text
    @zoom_text : GSDL::Text
    @controls_text : GSDL::Text

    GRID_SIZE = 32

    def initialize
      super(:start)

      Input.set(:left) { Keys.pressed?([Keys::A, Keys::Left]) }
      Input.set(:right) { Keys.pressed?([Keys::D, Keys::Right]) }
      Input.set(:up) { Keys.pressed?([Keys::W, Keys::Up]) }
      Input.set(:down) { Keys.pressed?([Keys::S, Keys::Down]) }

      Input.set(:camera_left) { Keys.pressed?(Keys::J) }
      Input.set(:camera_right) { Keys.pressed?(Keys::L) }
      Input.set(:camera_up) { Keys.pressed?(Keys::I) }
      Input.set(:camera_down) { Keys.pressed?(Keys::K) }

      Input.set(:switch_mode) { Keys.just_pressed?(Keys::Space) }
      Input.set(:toggle_lerp) { Keys.just_pressed?(Keys::L) }
      Input.set(:zoom_in) { Keys.pressed?(Keys::E) }
      Input.set(:zoom_out) { Keys.pressed?(Keys::Q) }
      Input.set(:shake) { Keys.just_pressed?(Keys::X) }

      @boundary = GSDL::Rect.new(x: 0, y: 0, w: Game.width + GRID_SIZE * 4, h: Game.height + GRID_SIZE * 4)

      @camera = GSDL::Camera.new(width: Game.width, height: Game.height)
      @camera.set_boundary(@boundary)
      @camera.type = GSDL::Camera::Type::CenterOnTargetWithBoundary

      @player = Player.new(key: "player", width: 32, height: 64)
      @player.x = 100
      @player.y = 100

      @info_text = GSDL::Text.new(
        text: "Mode: CenterOnTargetWithBoundary",
        x: 10,
        y: 10,
        color: GSDL::Color::White
      )
      @zoom_text = GSDL::Text.new(
        text: "Zoom: 1.0 (Lerp: OFF)",
        x: 10,
        y: 40,
        color: GSDL::Color::White
      )
      @controls_text = GSDL::Text.new(
        text: "SPACE: cycle mode\nL: toggle lerp\nQ/E: zoom\nX: shake",
        x: 10,
        y: 70,
        color: GSDL::Color::White
      )
    end

    def update(dt : Float32)
      if Input.action?(:toggle_lerp)
        if @camera.lerp_speed == 0
          @camera.lerp_speed = 5.0_f32
        else
          @camera.lerp_speed = 0_f32
        end
      end

      if Input.action?(:switch_mode)
        case @camera.type
        when GSDL::Camera::Type::CenterOnTargetWithBoundary
          @camera.type = GSDL::Camera::Type::Manual
          @info_text.text = "Mode: Manual"
          @controls_text.text = "IJKL: move camera\nSPACE: cycle mode\nL: toggle lerp\nQ/E: zoom\nX: shake"
        when GSDL::Camera::Type::Manual
          @camera.type = GSDL::Camera::Type::CenterOnTarget
          @info_text.text = "Mode: CenterOnTarget"
          @controls_text.text = "SPACE: cycle mode\nL: toggle lerp\nQ/E: zoom\nX: shake"
        when GSDL::Camera::Type::CenterOnTarget
          @camera.type = GSDL::Camera::Type::Fixed
          @info_text.text = "Mode: Fixed"
        when GSDL::Camera::Type::Fixed
          @camera.type = GSDL::Camera::Type::AutoScroll
          @camera.scroll_speed_x = 100_f32
          @camera.scroll_speed_y = 50_f32
          @info_text.text = "Mode: AutoScroll (100, 50)"
        when GSDL::Camera::Type::AutoScroll
          @camera.type = GSDL::Camera::Type::CenterOnTargetWithBoundary
          @camera.scroll_speed_x = 0_f32
          @camera.scroll_speed_y = 0_f32
          @info_text.text = "Mode: CenterOnTargetWithBoundary"
        end
      end

      @player.update(dt, @boundary)

      if @camera.type == GSDL::Camera::Type::CenterOnTarget || @camera.type == GSDL::Camera::Type::CenterOnTargetWithBoundary
        @camera.look_at(@player)
      end

      if Input.action?(:zoom_in)
        @camera.zoom += 1.0_f32 * dt
      end
      if Input.action?(:zoom_out)
        @camera.zoom -= 1.0_f32 * dt
        @camera.zoom = 0.1_f32 if @camera.zoom < 0.1_f32
      end

      if Input.action?(:shake)
        @camera.shake(0.5_f32, 20_f32)
      end

      lerp_status = @camera.lerp_speed > 0 ? "ON (#{@camera.lerp_speed})" : "OFF"
      @zoom_text.text = "Zoom: #{sprintf("%.2f", @camera.zoom)} (Lerp: #{lerp_status})"

      @camera.update(dt)
    end

    def draw(draw : GSDL::Draw)
      old_scale = draw.scale
      draw.scale = @camera.zoom

      draw_floor(draw)

      draw.scale = old_scale

      @player.draw(draw, @camera)
      @info_text.draw(draw)
      @zoom_text.draw(draw)
      @controls_text.draw(draw)
    end

    def draw_floor(draw : GSDL::Draw)
      end_x = @boundary.right
      end_y = @boundary.bottom

      (0...end_x).step(GRID_SIZE) do |x|
        (0...end_y).step(GRID_SIZE) do |y|
          # Checkerboard logic
          color = ((x / GRID_SIZE).to_i + (y / GRID_SIZE).to_i) % 2 == 0 ? GSDL::Color::Gray : GSDL::Color::DarkGray

          draw.rect_fill(
            rect: GSDL::FRect.new(
              x: @boundary.x + x.to_f32 - @camera.x,
              y: @boundary.y + y.to_f32 - @camera.y,
              w: GRID_SIZE.to_f32,
              h: GRID_SIZE.to_f32
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
