require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias Num = GSDL::Num

  class GameEx < GSDL::Game
    def initialize
      super(title: "Transitions Ex", width: 800, height: 600)
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(TransitionScene.new(0))
    end

    def check_scenes
      s = scene
      if s.name == :transition_scene && s.exit?
        next_index = s.as(TransitionScene).index + 1
        next_index = 0 if next_index > 5
        switch(TransitionScene.new(next_index))
      end
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class TransitionScene < GSDL::Scene
    getter index : Int32

    @name_str : String
    @title_text : GSDL::Text
    @instruction_text : GSDL::Text
    @toggle_text : GSDL::Text

    def initialize(@index : Int32)
      duration = 1.0_f32
      easing = GSDL::MathUtils::Easing::EaseInOut

      case @index
      when 0
        @name_str = "Fade + EaseInOut"
        t_in = GSDL::FadeTransition.new(GSDL::TransitionDirection::In, duration, started: true, easing: easing)
        t_out = GSDL::FadeTransition.new(GSDL::TransitionDirection::Out, duration, easing: easing)
      when 1
        @name_str = "Square + Linear"
        t_in = GSDL::SquareTransition.new(GSDL::TransitionDirection::In, duration, started: true, grid_size: 32)
        t_out = GSDL::SquareTransition.new(GSDL::TransitionDirection::Out, duration, grid_size: 32)
      when 2
        @name_str = "SlideLines + EaseOut"
        t_in = GSDL::SlideLinesTransition.new(GSDL::TransitionDirection::In, duration, started: true, line_count: 15, easing: GSDL::MathUtils::Easing::EaseOut)
        t_out = GSDL::SlideLinesTransition.new(GSDL::TransitionDirection::Out, duration, line_count: 15, easing: GSDL::MathUtils::Easing::EaseOut)
      when 3
        @name_str = "CircleMask + EaseIn"
        t_in = GSDL::CircleMaskTransition.new(GSDL::TransitionDirection::In, duration, started: true, easing: GSDL::MathUtils::Easing::EaseIn)
        t_out = GSDL::CircleMaskTransition.new(GSDL::TransitionDirection::Out, duration, easing: GSDL::MathUtils::Easing::EaseIn)
      when 4
        @name_str = "Boxes Shrink + EaseInOut"
        t_in = GSDL::BoxesShrinkTransition.new(GSDL::TransitionDirection::In, duration, started: true, box_size: 20, easing: easing)
        t_out = GSDL::BoxesShrinkTransition.new(GSDL::TransitionDirection::Out, duration, box_size: 20, easing: easing)
      when 5
        @name_str = "SlideLines + Linear (Many lines)"
        t_in = GSDL::SlideLinesTransition.new(GSDL::TransitionDirection::In, duration, started: true, line_count: 60)
        t_out = GSDL::SlideLinesTransition.new(GSDL::TransitionDirection::Out, duration, line_count: 60)
      else
        @name_str = "Fade + Linear"
        t_in = GSDL::FadeTransition.new(GSDL::TransitionDirection::In, duration, started: true)
        t_out = GSDL::FadeTransition.new(GSDL::TransitionDirection::Out, duration)
      end

      super(name: :transition_scene, transition_in: t_in, transition_out: t_out)

      @title_text = GSDL::Text.new(
        text: "Transition: #{@name_str}",
        x: 10,
        y: 10,
        color: GSDL::Color::White
      )
      @instruction_text = GSDL::Text.new(
        text: "Press SPACE to switch",
        x: 10,
        y: 30,
        color: GSDL::Color::White
      )
      @toggle_text = GSDL::Text.new(
        text: "press SPACE to toggle transition",
        x: 400,
        y: 300,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Lime
      )
    end

    def update(dt : Float32)
      transition_out.start if Keys.just_pressed?(Keys::Space)
      @title_text.update(dt)
      @instruction_text.update(dt)
      @toggle_text.update(dt)
    end

    def draw(draw : GSDL::Draw)
      # Draw some background pattern
      8.times do |i|
        8.times do |j|
          color = (i + j) % 2 == 0 ? GSDL::Color::DarkerGray : GSDL::Color::DimGray
          draw.rect_fill(GSDL::FRect.new(x: i * 100, y: j * 100, w: 100, h: 100), color: color)
        end
      end

      @title_text.draw(draw)
      @instruction_text.draw(draw)
      @toggle_text.draw(draw)
    end
  end

  GameEx.new.run
end
