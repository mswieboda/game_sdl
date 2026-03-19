require "../src/game_sdl"

module ShootEmUpEx
  alias Keys = GSDL::Keys
  alias Input = GSDL::Input

  class Game < GSDL::Game
    def initialize
      super(title: "Shoot 'em up Movement Example", width: 800, height: 600)
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MainScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [{"ship", "gfx/ship.png"}]
    end
  end

  class PlayerShip < GSDL::Sprite
    include GSDL::VerticalScrollController

    def initialize(key)
      super(
        key: key,
        origin: {0.5_f32, 0.5_f32},
        scale: {0.75_f32, 0.75_f32},
        source_rect: GSDL::FRect.new(w: 128_f32)
      )

      self.rotation = -90
      self.auto_scroll_speed = -150_f32 # Moving up
      self.strafing_speed_x = 300_f32
      self.thrust_speed_y = 150_f32
    end
  end

  class MainScene < GSDL::Scene
    @camera : GSDL::Camera
    @player : PlayerShip

    def initialize
      super(:main)

      # Setup inputs matching MoveController's expected actions
      Input.set(:move_left) { Keys.pressed?([Keys::A, Keys::Left]) }
      Input.set(:move_right) { Keys.pressed?([Keys::D, Keys::Right]) }
      Input.set(:move_up) { Keys.pressed?([Keys::W, Keys::Up]) }
      Input.set(:move_down) { Keys.pressed?([Keys::S, Keys::Down]) }

      @camera = GSDL::Camera.new(width: Game.width, height: Game.height)
      @camera.type = GSDL::Camera::Type::AutoScroll
      # Match the camera scroll speed to the ship's base auto_scroll_speed
      @camera.scroll_speed_y = -150_f32

      @player = PlayerShip.new(key: "ship")
      @player.x = Game.width / 2_f32
      @player.y = Game.height - 100_f32
    end

    def update(dt : Float32)
      @player.vertical_scroll_update(dt)

      # Keep player within screen bounds horizontally
      half_w = @player.width / 2_f32
      if @player.x < half_w
        @player.x = half_w
      elsif @player.x > Game.width - half_w
        @player.x = Game.width.to_f32 - half_w
      end

      # Keep player within screen bounds vertically relative to camera
      half_h = @player.height / 2_f32
      if @player.y < @camera.y + half_h
        @player.y = @camera.y + half_h
      elsif @player.y > @camera.y + Game.height - half_h
        @player.y = @camera.y + Game.height.to_f32 - half_h
      end

      @camera.update(dt)
    end

    def draw(draw : GSDL::Draw)
      draw_stars(draw)
      @player.draw(draw, @camera)
    end

    def draw_stars(draw : GSDL::Draw)
      # Procedurally draw stars based on world Y coordinate so they scroll correctly
      cam_y_int = @camera.y.to_i
      start_y = cam_y_int - (cam_y_int % 100)
      end_y = cam_y_int + Game.height + 100

      (start_y..end_y).step(100) do |y|
        (0..Game.width).step(100) do |x|
          seed = x * 31 + y * 17
          offset_x = (seed % 80) - 40
          offset_y = ((seed * 13) % 80) - 40

          world_x = x + offset_x
          world_y = y + offset_y

          screen_y = world_y - @camera.y
          if screen_y >= 0 && screen_y <= Game.height
            size = ((seed % 3) + 1).to_f32
            color = (seed % 5 == 0) ? GSDL::Color::Gray : GSDL::Color::DarkGray

            draw.rect_fill(
              rect: GSDL::FRect.new(x: world_x.to_f32, y: screen_y, w: size, h: size),
              color: color,
              z_index: -10
            )
          end
        end
      end
    end
  end

  Game.new.run
end
