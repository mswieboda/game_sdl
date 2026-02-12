require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias GamePad = GSDL::GamePad

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Gamepad Example", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_fonts
      GSDL::FontManager.load_default("assets/fonts/PressStart2P.ttf")
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = GamePadScene.new
    end
  end

  class GamePadScene < GSDL::Scene
    @instruction_text : GSDL::Text
    @button_states : Hash(LibSDL3::GamepadButton, GSDL::Text)
    @axis_states : Hash(LibSDL3::GamepadAxis, GSDL::Text)

    def initialize
      super(:gamepad)

      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)
      @instruction_text = GSDL::Text.new(text: "Press Gamepad buttons or move axes. Press ESC to exit.", color: color)
      @instruction_text.x = 20
      @instruction_text.y = 20

      @button_states = Hash(LibSDL3::GamepadButton, GSDL::Text).new
      @axis_states = Hash(LibSDL3::GamepadAxis, GSDL::Text).new

      y_offset = 60

      # Display for buttons
      [
        LibSDL3::GamepadButton::South,
        LibSDL3::GamepadButton::East,
        LibSDL3::GamepadButton::West,
        LibSDL3::GamepadButton::North,
        LibSDL3::GamepadButton::DPADUp,
        LibSDL3::GamepadButton::DPADDown,
        LibSDL3::GamepadButton::DPADLeft,
        LibSDL3::GamepadButton::DPADRight,
        LibSDL3::GamepadButton::LeftShoulder,
        LibSDL3::GamepadButton::RightShoulder,
      ].each_with_index do |button, i|
        text = GSDL::Text.new(text: "#{button}: Released", color: color)
        text.x = 20
        text.y = (y_offset + (i * 30)).to_f32
        @button_states[button] = text
      end

      y_offset += @button_states.size * 30 + 30

      # Display for axes
      [
        LibSDL3::GamepadAxis::LeftX,
        LibSDL3::GamepadAxis::LeftY,
        LibSDL3::GamepadAxis::RightX,
        LibSDL3::GamepadAxis::RightY,
        LibSDL3::GamepadAxis::LeftTrigger,
        LibSDL3::GamepadAxis::RightTrigger,
      ].each_with_index do |axis, i|
        text = GSDL::Text.new(text: "#{axis}: 0", color: color)
        text.x = 20
        text.y = (y_offset + (i * 30)).to_f32
        @axis_states[axis] = text
      end
    end

    def update(dt : Float32)
      if Keys.pressed?(Keys::Escape)
        @exit = true
        return
      end

      # Update button states display
      @button_states.each do |button, text_obj|
        if GamePad.just_pressed?(button)
          text_obj.text = "#{button}: JustPressed"
        elsif GamePad.pressed?(button)
          text_obj.text = "#{button}: Pressed"
        elsif GamePad.just_released?(button)
          text_obj.text = "#{button}: JustReleased"
        else
          text_obj.text = "#{button}: Released"
        end
      end

      # Update axis states display
      @axis_states.each do |axis, text_obj|
        value = GamePad.axis_value(axis)
        text_obj.text = "#{axis}: #{value}"
      end
    end

    def draw(renderer : GSDL::Renderer)
      @instruction_text.draw(renderer)
      @button_states.each_value { |text_obj| text_obj.draw(renderer) }
      @axis_states.each_value { |text_obj| text_obj.draw(renderer) }
    end

    def destroy
      @instruction_text.destroy
      @button_states.each_value { |text_obj| text_obj.destroy }
      @axis_states.each_value { |text_obj| text_obj.destroy }
      super
    end
  end

  Game.new.run
end
