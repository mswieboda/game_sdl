require "../src/game_sdl"

module SliderExample
  class Game < GSDL::Game
    def initialize
      super(title: "UI Slider Example", width: 800, height: 600)
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
    @h_slider : GSDL::Slider
    @v_slider : GSDL::Slider
    @h_label : GSDL::Text
    @v_label : GSDL::Text
    @instructions : GSDL::Text

    def initialize
      super(:main)

      @h_slider = GSDL::Slider.new(
        x: 400, y: 200, width: 300, height: 16,
        min_value: 0.0, max_value: 100.0, value: 50.0,
        origin: {0.5_f32, 0.5_f32},
        on_change: ->(val : Float32) {
          # Callback test
        }
      )

      @v_slider = GSDL::Slider.new(
        x: 100, y: 300, width: 16, height: 300,
        min_value: 0.0, max_value: 1.0, value: 0.5,
        orientation: GSDL::Slider::Orientation::Vertical,
        origin: {0.5_f32, 0.5_f32}
      )

      @h_label = GSDL::Text.new(text: "Value: 50", x: 400, y: 150, origin: {0.5_f32, 0.5_f32})
      @v_label = GSDL::Text.new(text: "Volume: 0.5", x: 100, y: 120, origin: {0.5_f32, 0.5_f32}, scale: {0.75_f32, 0.75_f32})
      
      @instructions = GSDL::Text.new(
        text: "Drag the sliders to change values",
        x: 400, y: 550,
        origin: {0.5_f32, 0.5_f32},
        scale: {0.75_f32, 0.75_f32}
      )
    end

    def update(dt : Float32)
      @h_slider.update(dt)
      @v_slider.update(dt)
      @instructions.update(dt)
      @h_label.update(dt)
      @v_label.update(dt)

      @h_label.text = "Value: #{@h_slider.value.to_i}"
      @v_label.text = "Volume: #{@v_slider.value.round(2)}"
    end

    def draw(draw : GSDL::Draw)
      @h_slider.draw(draw)
      @v_slider.draw(draw)
      @h_label.draw(draw)
      @v_label.draw(draw)
      @instructions.draw(draw)
    end
  end

  Game.new.run
end
