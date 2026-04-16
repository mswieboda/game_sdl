require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def initialize
      super(title: "Dialog Example")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(DialogScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_dialogs
      ["data/dialog.yml"]
    end
  end

  class DialogScene < GSDL::Scene
    @dialog_box_rpg : GSDL::DialogBox
    @dialog_box_side : GSDL::DialogBox
    @active_box : GSDL::DialogBox
    @game_state : Hash(String, Bool)

    def initialize
      super(:dialog)
      @game_state = Hash(String, Bool).new

      GSDL::Input.set(:menu_up) { GSDL::Keys.just_pressed?([GSDL::Keys::W, GSDL::Keys::Up]) }
      GSDL::Input.set(:menu_down) { GSDL::Keys.just_pressed?([GSDL::Keys::S, GSDL::Keys::Down]) }
      GSDL::Input.set(:menu_select) { GSDL::Keys.just_pressed?([GSDL::Keys::Return, GSDL::Keys::Space, GSDL::Keys::E]) }

      @dialog_box_rpg = GSDL::DialogBox.new(style: GSDL::DialogStyle.classic_rpg)
      @dialog_box_side = GSDL::DialogBox.new(style: GSDL::DialogStyle.side_panel)

      setup_callbacks(@dialog_box_rpg)
      setup_callbacks(@dialog_box_side)

      @active_box = @dialog_box_rpg
    end

    def setup_callbacks(box)
      box.on_action do |action|
        puts "ACTION: #{action}"
        case action
        when "open_shop"
          puts "Player is opening the shop."
        end
      end

      box.on_condition do |condition|
        puts "CONDITION: #{condition}"
        result = @game_state[condition]? || false
        puts " -> #{result}"
        result
      end
    end

    def update(dt)
      @active_box.update(dt)

      # For testing, we'll pretend we've met the dwarf after Tab pressed.
      if GSDL::Keys.just_pressed?(GSDL::Keys::Tab)
        puts "EVENT: Met the dwarf!"
        @game_state["has_met_dwarf"] = true
      end

      if !@active_box.is_active
        if GSDL::Keys.just_pressed?(GSDL::Keys::One)
          @active_box = @dialog_box_rpg
          @active_box.start("merchant_intro")
        elsif GSDL::Keys.just_pressed?(GSDL::Keys::Two)
          @active_box = @dialog_box_side
          @active_box.start("merchant_intro")
        end
      end
    end

    def draw(draw)
      @active_box.draw(draw)

      unless @active_box.is_active
        font = GSDL::Font.default
        text1 = GSDL::Text.new(
          font: font,
          text: "Press 1 for Classic RPG Style",
          x: 400,
          y: 280,
          origin: {0.5_f32, 0.5_f32}
        )
        text2 = GSDL::Text.new(
          font: font,
          text: "Press 2 for Side Panel Style",
          x: 400,
          y: 320,
          origin: {0.5_f32, 0.5_f32}
        )
        text1.draw(draw)
        text2.draw(draw)
      end
    end
  end

  Game.new.run
end
