require "../src/game_sdl"

module MouseDragExample
  class Game < GSDL::Game
    def initialize
      super(title: "Mouse Dragging Example", width: 800, height: 600)
    end

    def init
      GSDL::Events.esc_exits = true
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
    @box : GSDL::Box
    @is_dragging : Bool = false
    @offset_x : GSDL::Num = 0
    @offset_y : GSDL::Num = 0
    @info_text : GSDL::Text

    def initialize
      super(:main)
      @box = GSDL::Box.new(
        width: 100, height: 100,
        x: 350, y: 250,
        color: GSDL::Color::RoyalBlue,
        border_radius: 8
      )

      @info_text = GSDL::Text.new(
        text: "Click and drag the box",
        x: 400, y: 50,
        origin: {0.5_f32, 0.5_f32}
      )
    end

    def update(dt : Float32)
      if GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
        if @box.in?(GSDL::Mouse.x, GSDL::Mouse.y)
          @is_dragging = true
          @offset_x = GSDL::Mouse.x - @box.x
          @offset_y = GSDL::Mouse.y - @box.y
          @box.color = GSDL::Color::Orange
        end
      end

      if GSDL::Mouse.just_released?(GSDL::Mouse::ButtonLeft)
        @is_dragging = false
        @box.color = GSDL::Color::RoyalBlue
      end

      if @is_dragging
        @box.x = GSDL::Mouse.x - @offset_x
        @box.y = GSDL::Mouse.y - @offset_y
      end

      @info_text.text = "Dragging: #{@is_dragging}\nOffset: #{GSDL::Mouse.drag_offset_x}, #{GSDL::Mouse.drag_offset_y}\nDX/DY: #{GSDL::Mouse.dx}, #{GSDL::Mouse.dy}"
    end

    def draw(draw : GSDL::Draw)
      @box.draw(draw)
      @info_text.draw(draw)
    end
  end

  Game.new.run
end
