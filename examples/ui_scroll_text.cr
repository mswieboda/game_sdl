require "../src/game_sdl"

module ScrollTextEx
  class Game < GSDL::Game
    def initialize
      super(title: "Scrollable Text View Example", width: 800, height: 600)
    end

    def init
      GSDL::Events.esc_exits = true
      
      GSDL::Input.set(:scroll_up) { GSDL::Keys.pressed?(GSDL::Keys::Up) }
      GSDL::Input.set(:scroll_down) { GSDL::Keys.pressed?(GSDL::Keys::Down) }

      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = MainScene.new
    end
  end

  class MainScene < GSDL::Scene
    @scroll_view : GSDL::ScrollTextView
    @instructions : GSDL::Text

    def initialize
      super(:main)

      long_text = <<-TEXT
      SCROLLABLE TEXT VIEW
      
      This component allows you to display large blocks of text within a fixed viewport.
      
      FEATURES:
      - Automatic line wrapping
      - Clipping within the viewport
      - Mouse wheel scrolling
      - Origin-based positioning
      - Tweenable properties
      
      GSDL is a game framework built on Crystal and SDL3. It aims to be simple yet powerful for 2D game development.
      
      STORY OF THE VOID:
      Deep in the code, where the segments meet the stack, lies the Void. It is a place of uninitialized variables and dangling pointers. 
      
      Many have ventured there, but few have returned with their memory intact. Some say the Garbage Collector is the only thing that keeps the Void at bay.
      
      Others believe that the Void is the true nature of reality, and that the Heap is just a temporary illusion.
      
      Regardless of what you believe, one thing is certain: you need a good ScrollTextView to read all about it!
      
      LOREM IPSUM:
      Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. 
      
      Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
      
      Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
      
      Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
      
      END OF CREDITS.
      TEXT

      @scroll_view = GSDL::ScrollTextView.new(
        text: long_text,
        width: 400,
        height: 300,
        x: 400,
        y: 300,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Cyan,
        padding: 20
      )

      @instructions = GSDL::Text.new(
        text: "USE MOUSE WHEEL TO SCROLL",
        x: 400,
        y: 100,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White
      )
    end

    def update(dt : Float32)
      @scroll_view.update(dt)
      @instructions.update(dt)
    end

    def draw(draw : GSDL::Draw)
      # Draw a background box for the scroll view
      draw.rect_outline(
        rect: GSDL::FRect.new(
          x: @scroll_view.draw_x,
          y: @scroll_view.draw_y,
          w: @scroll_view.draw_width,
          h: @scroll_view.draw_height
        ),
        color: GSDL::Color::Gray
      )

      @scroll_view.draw(draw)
      @instructions.draw(draw)
    end
  end

  Game.new.run
end
