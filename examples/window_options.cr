require "../src/game_sdl"

# This example demonstrates the new boolean window configuration parameters 
# in GSDL::Game.initialize. It cycles through different window states 
# by restarting the game instance with new flags.

module WindowOptionsEx
  class OptionsScene < GSDL::Scene
    def initialize(@current_test : String)
      super(:options)
    end

    def update(dt : Float32)
      super
      if GSDL::Input.action?(:toggle)
        GSDL::Game.quit!
      end
    end

    def draw(draw : GSDL::Draw)
      draw.color = GSDL::Color::White
      
      title_font = GSDL::Font.default.copy
      title_font.size = 24
      draw.text(GSDL::Text.new(text: "Window Options Demo", x: 40, y: 40, font: title_font))

      info_font = GSDL::Font.default.copy
      info_font.size = 16
      draw.text(GSDL::Text.new(text: "Current Test: #{@current_test}", x: 40, y: 100, color: GSDL::Color::Cyan, font: info_font))
      
      draw.text(GSDL::Text.new(text: "Press SPACE to cycle to the next mode", x: 40, y: 160))
      draw.text(GSDL::Text.new(text: "Press ESC to exit completely", x: 40, y: 190))

      # Display current window status
      win = GSDL::Game.instance.window
      draw.text(GSDL::Text.new(text: "Window Size: #{win.size[0]}x#{win.size[1]}", x: 40, y: 250, color: GSDL::Color::Gray))
    end
  end

  class WindowGame < GSDL::Game
    def initialize(
      @test_name : String,
      resizable = false,
      fullscreen = false,
      maximized = false,
      borderless = false,
      always_on_top = false
    )
      super(
        title: "GSDL - #{@test_name}",
        resizable: resizable,
        fullscreen: fullscreen,
        maximized: maximized,
        borderless: borderless,
        always_on_top: always_on_top
      )
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Input.set(:toggle) { GSDL::Keys.just_pressed?(GSDL::Keys::Space) }
      GSDL::Game.push(OptionsScene.new(@test_name))
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end
end

# Test Runner logic to cycle through different games
tests = [
  ->{ WindowOptionsEx::WindowGame.new("Default (800x600)") },
  ->{ WindowOptionsEx::WindowGame.new("Resizable", resizable: true) },
  ->{ WindowOptionsEx::WindowGame.new("Maximized (Fixed)", maximized: true, resizable: false) },
  ->{ WindowOptionsEx::WindowGame.new("Borderless", borderless: true) },
  ->{ WindowOptionsEx::WindowGame.new("Always On Top", always_on_top: true) },
  ->{ WindowOptionsEx::WindowGame.new("Fullscreen", fullscreen: true) },
]

test_index = 0

while test_index < tests.size
  game = tests[test_index].call
  game.run
  
  # If the user pressed ESC, GSDL::Events.exit? will be true
  break if GSDL::Events.exit?
  
  test_index += 1
  puts "Moving to test #{test_index + 1}..."
end
