require "../../src/game_sdl"

# Configure a beautiful Violet/Purple theme for this FlowBox wrapping showcase!
GSDL::ColorScheme.configure(
  main: "#8b5cf6",              # Sleek Violet as primary accent
  ui_button_hover: "#7c3aed",   # Darker violet on hover
)

module UIExample
  class FlowBoxGame < GSDL::Game
    def initialize
      super(title: "GSDL FlowBox Layout Showcase", width: 1024, height: 768)
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(FlowScene.new)
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
      false # Let engine update other input states
    end
  end

  class FlowScene < GSDL::Scene
    include GSDL::UI

    @root_canvas : RootCanvas
    @event_handler : UIHandler
    @selected_label : Text?

    def initialize
      super(:flow_showcase)

      # Create our main 1024x768 canvas container
      @root_canvas = RootCanvas.new(1024, 768) do
        # 1. Main Title Header (Absolutely positioned)
        text(
          text: "GSDL FlowBox Layout Showcase",
          font_size: 20,
          color: GSDL::Color::Yellow,
          x: 30,
          y: 30
        )

        text(
          text: "Resolution: 1024x768 | Esc to Quit",
          font_size: 10,
          color: GSDL::Color::Gray,
          x: 30,
          y: 60
        )

        # 2. Main content container - HBox to place left sidebar and right flow decks side-by-side
        hbox(
          x: 30,
          y: 95,
          width: 964,
          height: 590,
          spacing: 24,
          stretch: true
        ) do
          # Left Sidebar: Information Card & Action logs
          vbox(
            width: 280,
            height: GSDL::UI::FillParent,
            spacing: 16,
            stretch: true
          ) do
            text(
              text: "SYSTEM CONTROL:",
              font_size: 12,
              color: GSDL::Color::White
            )

            # Interactive Reset Button (Defaults to FitContent width/height and flex: 0)
            button(
              text: "Reset Selection",
              height: 40
            ) do
              if lbl = @selected_label
                lbl.text_entity.text = "None clicked yet."
              end
            end

            text(
              text: "ACTION LOG:",
              font_size: 12,
              color: GSDL::Color::White
            )

            # Details card showing currently selected/clicked items (Uses flex: 1 to fill available sidebar height)
            log_box = vbox(
              width: GSDL::UI::FillParent,
              padding: GSDL::UI::Spacing.new(all: 12),
              flex: 1_u8
            ) do
              text(
                text: "Last clicked button:",
                font_size: 10,
                color: GSDL::Color::Gray
              )
              @selected_label = text(
                text: "None clicked yet.",
                font_size: 10,
                color: GSDL::Color::Lime
              )
            end
            log_box.background_color = GSDL::Color.parse("#1a1a1f")
          end

          # Right Deck: FlowBoxes stacked vertically (Uses flex: 1 to fill remaining horizontal width)
          vbox(
            width: 660,
            height: GSDL::UI::FillParent,
            spacing: 24,
            stretch: true,
            flex: 1_u8
          ) do
            # Panel A: Horizontal FlowBox (Wrapping Buttons)
            vbox(
              width: GSDL::UI::FillParent,
              height: GSDL::UI::FitContent,
              spacing: 8,
              stretch: true
            ) do
              text(
                text: "Horizontal Wrapping (Varying Button Widths):",
                font_size: 12,
                color: GSDL::Color::Cyan
              )

              # FlowBox automatically wraps elements onto new lines
              # All buttons size-to-content and wrap automatically with zero boilerplate!
              flow_box(
                orientation: Orientation::Horizontal,
                spacing: 8,
                line_spacing: 8,
                width: GSDL::UI::FillParent,
                height: GSDL::UI::FitContent,
                background_color: GSDL::Color.parse("#16161a"),
                padding: GSDL::UI::Spacing.new(all: 12)
              ) do
                button(text: "Sword", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Sword") }
                button(text: "Iron Shield", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Iron Shield") }
                button(text: "Red Potion", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Red Potion") }
                button(text: "Golden Helmet", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Golden Helmet") }
                button(text: "Ring", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Ring") }
                button(text: "Phoenix Elixir", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Phoenix Elixir") }
                button(text: "Bow", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Bow") }
                button(text: "Staff of Wizardry", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Staff of Wizardry") }
                button(text: "7", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("7") }
                button(text: "Eight", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Eight") }
                button(text: "Great Boots", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Great Boots") }
                button(text: "Mana Orb", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Mana Orb") }
                button(text: "Axe", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Axe") }
                button(text: "Thirteen", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Thirteen") }
                button(text: "Ancient Relic", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Ancient Relic") }
                button(text: "Tome of Fire", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Tome of Fire") }
                button(text: "17", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("17") }
                button(text: "Cape", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Cape") }
              end
            end

            # Panel B: Vertical FlowBox (Wrapping Columns)
            vbox(
              width: GSDL::UI::FillParent,
              height: GSDL::UI::FitContent,
              spacing: 8,
              stretch: true
            ) do
              text(
                text: "Vertical Wrapping (Wrapped Columns, Fixed Height = 140px):",
                font_size: 12,
                color: GSDL::Color::Cyan
              )

              # FlowBox automatically wraps elements onto new columns
              flow_box(
                orientation: Orientation::Vertical,
                spacing: 8,
                line_spacing: 16,
                width: GSDL::UI::FillParent,
                height: 140,
                background_color: GSDL::Color.parse("#1e1e24"),
                padding: GSDL::UI::Spacing.new(all: 12)
              ) do
                button(text: "Item Alpha", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Item Alpha") }
                button(text: "Item Beta", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Item Beta") }
                button(text: "Item Gamma", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Item Gamma") }
                button(text: "Item Delta", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Item Delta") }
                button(text: "Item Epsilon", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Item Epsilon") }
                button(text: "Item Zeta", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Item Zeta") }
                button(text: "Item Eta", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Item Eta") }
                button(text: "Item Theta", padding: Spacing.new(horizontal: 12, vertical: 6)) { update_log("Item Theta") }
              end
            end
          end
        end

        # 3. Bottom Status Bar (Snaps to bottom-left of canvas via anchor)
        status_bar(
          spacing: 15,
          padding: GSDL::UI::Spacing.new(all: 8)
        ) do
          text(
            text: "Status: Active",
            font_size: 10,
            color: GSDL::Color::Lime
          )
          text(
            text: "FlowBox Demo running...",
            font_size: 10,
            color: GSDL::Color::Gray,
            h_align: GSDL::HorizontalAlign::Right,
            flex: 2_u8
          )
        end
      end


      # Connect the RootCanvas to the engine's event processing system via our event handler
      @event_handler = UIHandler.new(@root_canvas)
      GSDL::Game.instance.register_event_handler(@event_handler)
    end

    def update_log(name : String)
      if lbl = @selected_label
        lbl.text_entity.text = name
      end
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

  FlowBoxGame.new.run
end
