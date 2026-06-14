require "../../src/game_sdl"

# Configure a beautiful Indigo theme for this specific grid layout showcase!
GSDL::ColorScheme.configure(
  main: "#6366f1",              # Sleek Indigo as primary accent
  ui_button_hover: "#4f46e5",   # Darker indigo on hover
)

module UIExample
  class GridBoxGame < GSDL::Game
    def initialize
      super(title: "GSDL GridBox Layout Showcase", width: 1024, height: 768)
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(GridScene.new)
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

  class GridScene < GSDL::Scene
    include GSDL::UI

    @root_canvas : RootCanvas
    @event_handler : UIHandler
    @selected_label : Text?

    def initialize
      super(:grid_showcase)

      # Create our main 1024x768 canvas container
      @root_canvas = RootCanvas.new(1024, 768) do
        # 1. Main Title Header (Absolutely positioned)
        text(
          text: "GSDL GridBox Container Showcase",
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

        # 2. Main content container - HBox to place left sidebar and right grid deck side-by-side
        hbox(
          x: 30,
          y: 95,
          width: 964,
          height: 590,
          spacing: 24,
          stretch: true
        ) do
          # Left Sidebar: Information Card & Stats overview
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

            # Interactive Reset Button
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

            # Details card showing currently selected/clicked items
            log_box = vbox(
              width: GSDL::UI::FillParent,
              padding: 12,
              flex: 1_u8
            ) do
              text(
                text: "Selection Info:",
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

          # Right Deck: Grid Displays stacked vertically
          vbox(
            width: 660,
            height: GSDL::UI::FillParent,
            spacing: 20,
            stretch: true,
            flex: 1_u8
          ) do
            # Panel A: Uniform Grid Layout (Shop/Inventory)
            vbox(
              width: GSDL::UI::FillParent,
              height: GSDL::UI::FitContent,
              spacing: 8,
              stretch: true
            ) do
              text(
                text: "Uniform Inventory Grid (4 Columns, Equal Cells):",
                font_size: 12,
                color: GSDL::Color::Cyan
              )

              # Showcase beautiful 4x2 inventory
              grid_box(
                columns: 4,
                col_spacing: 12,
                row_spacing: 12,
                uniform_cells: true,
                width: GSDL::UI::FillParent,
                height: 190,
                background_color: GSDL::Color.parse("#16161a"),
                padding: 10
              ) do
                button(text: "Sword") { update_log("Sword") }
                button(text: "Shield") { update_log("Shield") }
                button(text: "Potion") { update_log("Potion") }
                button(text: "Helmet") { update_log("Helmet") }
                button(text: "Ring") { update_log("Ring") }
                button(text: "Elixir") { update_log("Elixir") }
                button(text: "Bow") { update_log("Bow") }
                button(text: "Staff") { update_log("Staff") }
              end
            end

            # Panel B: Non-Uniform Grid Layout (Character Attributes Form)
            vbox(
              width: GSDL::UI::FillParent,
              height: GSDL::UI::FitContent,
              spacing: 8,
              stretch: true
            ) do
              text(
                text: "Non-Uniform Grid Form (Labels & Controls Aligned):",
                font_size: 12,
                color: GSDL::Color::Cyan
              )

              # 2 Column form, rows have varied widths dynamically matching content size
              grid_box(
                columns: 2,
                col_spacing: 24,
                row_spacing: 12,
                uniform_cells: false,
                width: GSDL::UI::FillParent,
                height: GSDL::UI::FitContent,
                background_color: GSDL::Color.parse("#1e1e24"),
                padding: 14
              ) do
                # Row 0
                text(text: "Adventurer Name:", font_size: 10, color: GSDL::Color::White)
                button(
                  text: "Galahad the Brave",
                  width: 380,
                  height: 32,
                  padding: GSDL::UI::Spacing.new(0, 0, 0, 16),
                  h_align: GSDL::HorizontalAlign::Left
                ) { update_log("Galahad the Brave") }

                # Row 1
                text(text: "Hero Profession:", font_size: 10, color: GSDL::Color::White)
                button(
                  text: "Paladin (Level 12)",
                  width: 380,
                  height: 32,
                  padding: GSDL::UI::Spacing.new(0, 0, 0, 16),
                  h_align: GSDL::HorizontalAlign::Left
                ) { update_log("Paladin (Level 12)") }

                # Row 2
                text(text: "Faction Allegiance:", font_size: 10, color: GSDL::Color::White)
                button(
                  text: "Order of the Eclipse",
                  width: 380,
                  height: 32,
                  padding: GSDL::UI::Spacing.new(0, 0, 0, 16),
                  h_align: GSDL::HorizontalAlign::Left
                ) { update_log("Order of the Eclipse") }
              end
            end
          end
        end

        # 3. Bottom Status Bar (Snaps to bottom of canvas via anchor)
        status_bar(
          spacing: 15,
          padding: 10
        ) do
          text(
            text: "Status: Ready",
            font_size: 10,
            color: GSDL::Color::Lime
          )
          text(
            text: "GSDL Layout Engine | #{Time.local.to_s("%Y-%m-%d %H:%M")}",
            font_size: 10,
            color: GSDL::Color::Gray,
            h_align: GSDL::HorizontalAlign::Right,
            flex: 1_u8
          )
        end
      end

      # Connect event handler to engine
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

  GridBoxGame.new.run
end
