require "../src/game_sdl"

module UIExample
  class Game < GSDL::Game
    def initialize
      super(title: "Nested UI DSL Showcase")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MainScene.new)
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

  class MainScene < GSDL::Scene
    include GSDL::UI

    @root_canvas : RootCanvas
    @event_handler : UIHandler
    @click_count = 0

    def initialize
      super(:main)

      # Build our dynamic, fully nested UI tree cleanly using the LayoutScope block-based DSL!
      @root_canvas = RootCanvas.new(800, 600) do
        vbox(stretch: true) do
          # 1. Title Bar
          text(
            text: "GameSDL UI DSL Demo",
            font_size: 18,
            color: GSDL::Color::Yellow,
            x: 20,
            y: 20
          )

          # 2. Left Panel: Control Panel
          vbox(
            x: 40,
            y: 80,
            width: 320,
            height: 440,
            margin: GSDL::UI::Spacing.new(all: 64),
            spacing: 12,
            stretch: true
          ) do
            text(
              text: "Interactive Controls:",
              font_size: 14,
              color: GSDL::Color::White
            )

            btn = button(
              text: "Click Me!",
              height: 36
            ) do
              # Note: button block is the on_click callback
              puts "Button clicked!"
            end

            # Showcase customized hover cursor and transition callbacks!
            btn.hover_cursor = GSDL::SystemCursor::Crosshair
            btn.on_hover_enter = ->(el : GSDL::UI::Element) {
              puts "Hover enter: #{el.class}"
            }
            btn.on_hover_leave = ->(el : GSDL::UI::Element) {
              puts "Hover leave: #{el.class}"
            }

            checkbox(
              text: "Toggle option",
              checked: true,
              height: 28,
              on_toggle: ->(checked : Bool) {
                puts "Checkbox toggled: #{checked}"
              }
            )

            text(
              text: "Choose option:",
              font_size: 12,
              color: GSDL::Color::Gray
            )

            radio_button(
              text: "Difficulty: Easy",
              group: :difficulty,
              checked: true,
              height: 28,
              on_select: -> {
                puts "Selected Easy"
              }
            )

            radio_button(
              text: "Difficulty: Hard",
              group: :difficulty,
              height: 28,
              on_select: -> {
                puts "Selected Hard"
              }
            )

            dropdown(
              options: ["Select 1", "Select 2", "Select 3", "Select 4", "Select 5", "Select 6"],
              height: 32,
              on_change: ->(val : String, idx : Int32) {
                puts "Dropdown changed to: #{val} (Index: #{idx})"
              }
            )
          end

          # 3. Bottom Status Bar
          status_bar(
            spacing: 15,
            padding: GSDL::UI::Spacing.new(all: 8),
          ) do
            text(
              text: "Status: Ready",
              font_size: 10,
              color: GSDL::Color::Lime
            )
            text(
              text: "Last updated: #{Time.local}",
              font_size: 10,
              color: GSDL::Color::Gray,
              h_align: GSDL::HorizontalAlign::Right,
              flex: 2_u8
            )
          end
        end
      end

      # Connect the RootCanvas to the engine's event processing system via our event handler
      @event_handler = UIHandler.new(@root_canvas)
      GSDL::Game.instance.register_event_handler(@event_handler)
    end

    def update(dt : Float32)
      super(dt)
      @root_canvas.update(dt)
    end

    def draw(draw : GSDL::Draw)
      super(draw)
      @root_canvas.draw(draw)
    end

    def destroy
      GSDL::Game.instance.unregister_event_handler(@event_handler)
    end
  end

  Game.new.run
end
