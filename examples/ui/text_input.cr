require "../../src/game_sdl"

GSDL::ColorScheme.configure(
  main: "#10b981",              # Emerald primary
  ui_button_hover: "#059669",   # Dark emerald
)

module UIExample
  class TextInputGame < GSDL::Game
    def initialize
      super(title: "GSDL TextInput Showcase", width: 1024, height: 768)
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(InputScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class UIHandler < GSDL::EventHandler
    def initialize(@root : GSDL::UI::RootCanvas)
    end

    def handle(event : GSDL::Event, window : SDL3::Window) : Bool
      @root.handle_event(event)
      false # Let the engine update global input state
    end
  end

  class InputScene < GSDL::Scene
    include GSDL::UI

    @root_canvas : RootCanvas?
    @event_handler : UIHandler
    @log_text : Text? = nil

    def initialize
      super(:text_input_showcase)

      @root_canvas = RootCanvas.new(1024, 768) do
        # Title
        text(
          text: "GSDL TextInput Showcase",
          font_size: 20,
          color: GSDL::Color::Yellow,
          x: 30,
          y: 30
        )

        text(
          text: "Click an input to focus. Type to edit. Esc to Exit",
          font_size: 10,
          color: GSDL::Color::Gray,
          x: 30,
          y: 60
        )

        # Main horizontal container splits inputs and log panel
        hbox(
          x: 30,
          y: 95,
          width: 964,
          height: 590,
          spacing: 24,
          stretch: true
        ) do
          # Left: Inputs Stack
          vbox(
            width: 480,
            height: GSDL::UI::FillParent,
            spacing: 12,
            stretch: true
          ) do
            text(
              text: "INTERACTIVE INPUTS:",
              font_size: 12,
              color: GSDL::Color::White
            )

            # 1. Standard TextInput
            text(text: "Username (Standard):", font_size: 10, color: GSDL::Color::Cyan)
            text_input(
              placeholder: "Enter username...",
              width: GSDL::UI::FillParent,
              height: 40,
              on_change: ->(val : String) { update_log("Username changing: '#{val}'") }
            ) do |val|
              update_log("Username submitted: '#{val}'")
            end

            # 2. Password TextInput (Masked)
            text(text: "Password (Masked):", font_size: 10, color: GSDL::Color::Cyan)
            text_input(
              placeholder: "Enter password...",
              mask_character: '*',
              width: GSDL::UI::FillParent,
              height: 40,
              on_change: ->(val : String) { update_log("Password changing: '#{val}'") }
            ) do |val|
              update_log("Password submitted: '#{val}'")
            end

            # 3. Max Length Input
            text(text: "Coupon Code (Max Length = 8):", font_size: 10, color: GSDL::Color::Cyan)
            text_input(
              placeholder: "CODE123",
              max_length: 8,
              width: GSDL::UI::FillParent,
              height: 40,
              on_change: ->(val : String) { update_log("Coupon changing: '#{val}'") }
            ) do |val|
              update_log("Coupon submitted: '#{val}'")
            end

            # 4. FitContent TextInput
            text(text: "FitContent Height Input:", font_size: 10, color: GSDL::Color::Cyan)
            text_input(
              placeholder: "Fit content...",
              width: GSDL::UI::FillParent,
              height: GSDL::UI::FitContent,
              on_change: ->(val : String) { update_log("FitContent changing: '#{val}'") }
            ) do |val|
              update_log("FitContent submitted: '#{val}'")
            end

            # 5. Centered TextInput
            text(text: "Centered text Alignment (Center / Center):", font_size: 10, color: GSDL::Color::Cyan)
            text_input(
              placeholder: "Centered...",
              h_align: GSDL::HorizontalAlign::Center,
              v_align: GSDL::VerticalAlign::Center,
              width: GSDL::UI::FillParent,
              height: 40,
              on_change: ->(val : String) { update_log("Centered changing: '#{val}'") }
            ) do |val|
              update_log("Centered submitted: '#{val}'")
            end

            # Simple button to clear/unfocus
            button(
              text: "Unfocus All",
              height: 40
            ) do
              @root_canvas.try(&.focused_element = nil)
              update_log("All inputs unfocused")
            end
          end

          # Right: Event Logs Card
          vbox(
            width: 460,
            height: GSDL::UI::FillParent,
            spacing: 16,
            stretch: true,
            flex: 1_u8
          ) do
            text(
              text: "EVENT LOGS:",
              font_size: 12,
              color: GSDL::Color::White
            )

            log_panel = vbox(
              width: GSDL::UI::FillParent,
              padding: GSDL::UI::Spacing.new(all: 16),
              flex: 1_u8
            ) do
              @log_text = text(
                text: "No events logged yet.",
                font_size: 10,
                color: GSDL::Color::Lime
              )
            end
            log_panel.background_color = GSDL::Color.parse("#1a1a1f")
          end
        end

        # Status Bar
        status_bar(
          spacing: 15,
          padding: GSDL::UI::Spacing.new(all: 8)
        ) do
          text(
            text: "Status: Ready",
            font_size: 10,
            color: GSDL::Color::Lime
          )
          text(
            text: "GSDL::UI::TextInput Showcase running...",
            font_size: 10,
            color: GSDL::Color::Gray,
            h_align: GSDL::HorizontalAlign::Right,
            flex: 2_u8
          )
        end
      end

      @event_handler = UIHandler.new(@root_canvas.not_nil!)
      GSDL::Game.instance.register_event_handler(@event_handler)
    end

    def update_log(message : String)
      if lbl = @log_text
        lbl.text_entity.text = message
      end
    end

    def update(dt : Float32)
      super(dt)
      @root_canvas.try(&.update(dt))
    end

    def draw(draw : GSDL::Draw)
      super(draw)
      @root_canvas.try(&.draw(draw))
    end

    def destroy
      GSDL::Game.instance.unregister_event_handler(@event_handler)
    end
  end

  TextInputGame.new.run
end
