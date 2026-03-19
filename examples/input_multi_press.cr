require "../src/game_sdl"

module MultiPressEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Multi-Press Ex", width: WIDTH, height: HEIGHT)
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MultiPressScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class MultiPressScene < GSDL::Scene
    @box : GSDL::Box
    @text : GSDL::TextBox

    def initialize
      super(:main)
      GSDL::Input.multi_tap_time_window = 250_u64
      @box = GSDL::Box.new(width: 32, height: 32, color: GSDL::Color::White)
      @box.x = 400
      @box.y = 300

      @text = GSDL::TextBox.new(
        text: "Double-tap Arrow Keys to dash.\nDouble-click Mouse Left to teleport and turn red.",
        color: GSDL::Color::White
      )
      @text.x = 10
      @text.y = 10
    end

    def update(dt : Float32)
      speed = 1
      dash_impulse = 100

      # Dash Impulse on the frame the second tap is registered
      if GSDL::Keys.just_pressed?(GSDL::Keys::Right) && GSDL::Keys.double_tap?(GSDL::Keys::Right)
        @box.x += dash_impulse
      end
      if GSDL::Keys.just_pressed?(GSDL::Keys::Left) && GSDL::Keys.double_tap?(GSDL::Keys::Left)
        @box.x -= dash_impulse
      end
      if GSDL::Keys.just_pressed?(GSDL::Keys::Up) && GSDL::Keys.double_tap?(GSDL::Keys::Up)
        @box.y -= dash_impulse
      end
      if GSDL::Keys.just_pressed?(GSDL::Keys::Down) && GSDL::Keys.double_tap?(GSDL::Keys::Down)
        @box.y += dash_impulse
      end

      # Normal Continuous Movement
      if GSDL::Keys.pressed?(GSDL::Keys::Right)
        @box.x += speed
      end
      if GSDL::Keys.pressed?(GSDL::Keys::Left)
        @box.x -= speed
      end
      if GSDL::Keys.pressed?(GSDL::Keys::Up)
        @box.y -= speed
      end
      if GSDL::Keys.pressed?(GSDL::Keys::Down)
        @box.y += speed
      end

      # Clamp to screen bounds
      @box.x = @box.x.clamp(0_f32, (WIDTH - @box.width).to_f32)
      @box.y = @box.y.clamp(0_f32, (HEIGHT - @box.height).to_f32)

      # Change color and teleport on mouse double-click
      if GSDL::Mouse.double_tap?(GSDL::Mouse::ButtonLeft)
        @box.x = GSDL::Mouse.x.to_f32
        @box.y = GSDL::Mouse.y.to_f32
        @box.color = GSDL::Color::Red
      elsif GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
        @box.color = GSDL::Color::Blue
      end

      if GSDL::Mouse.just_released?(GSDL::Mouse::ButtonLeft)
        @box.color = GSDL::Color::White
      end
    end

    def draw(draw : GSDL::Draw)
      @box.draw(draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
