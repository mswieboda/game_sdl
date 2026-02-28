require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def initialize
      super(title: "Dialog Example", width: 800, height: 600)
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
      GSDL::DialogManager.load("data/dialog.yml")
      super
      @scene = DialogScene.new

      GSDL::Input.set(:menu_up) { GSDL::Keys.just_pressed?([GSDL::Keys::W, GSDL::Keys::Up]) }
      GSDL::Input.set(:menu_down) { GSDL::Keys.just_pressed?([GSDL::Keys::S, GSDL::Keys::Down]) }
      GSDL::Input.set(:menu_select) { GSDL::Keys.just_pressed?([GSDL::Keys::Return, GSDL::Keys::Space, GSDL::Keys::E]) }
    end
  end

  class DialogScene < GSDL::Scene
    @dialog_box : GSDL::DialogBox
    @game_state : Hash(String, Bool)

    def initialize
      super(:dialog)
      @game_state = Hash(String, Bool).new

      @dialog_box = GSDL::DialogBox.new
      @dialog_box.on_action do |action|
        puts "ACTION: #{action}"
        case action
        when "open_shop"
          puts "Player is opening the shop."
        end
      end

      @dialog_box.on_condition do |condition|
        puts "CONDITION: #{condition}"
        result = @game_state[condition]? || false
        puts " -> #{result}"
        result
      end

      @dialog_box.start("merchant_intro")
    end

    def update(dt)
      @dialog_box.update(dt)

      # For testing, we'll pretend we've met the dwarf after Tab pressed.
      if GSDL::Keys.just_pressed?(GSDL::Keys::Tab)
        puts "EVENT: Met the dwarf!"
        @game_state["has_met_dwarf"] = true
      end
    end

    def draw(draw)
      @dialog_box.draw(draw)
    end
  end

  Game.new.run
end
