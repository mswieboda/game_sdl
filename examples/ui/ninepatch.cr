require "../../src/game_sdl"

module NinePatchExample
  class Game < GSDL::Game
    def initialize
      super(title: "Nine-Patch Skinning System Demo")
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
      false
    end
  end

  class MainScene < GSDL::Scene
    include GSDL::UI

    @root_canvas : RootCanvas?
    @event_handler : UIHandler?

    def initialize
      super(:main)

      # 1. Create a programmatically generated 9-patch panel texture (32x32)
      panel_surface = GSDL::Surface.new(32, 32)
      # Fill outer border: very dark gray/black
      panel_surface.fill(GSDL::Color.parse("#111827"))
      # Draw inner border frame: medium gray (thicker)
      panel_surface.draw_rect_fill(GSDL::Rect.new(3, 3, 26, 26), GSDL::Color.parse("#4b5563"))
      # Draw panel center: dark indigo
      panel_surface.draw_rect_fill(GSDL::Rect.new(12, 12, 8, 8), GSDL::Color.parse("#1e1b4b"))

      # Draw yellow 'X' markers in the corners to demonstrate non-scaling behavior
      yellow_color = GSDL::Color.parse("#fbbf24")
      [
        {3, 3},   # Top-Left
        {23, 3},  # Top-Right
        {3, 23},  # Bottom-Left
        {23, 23}  # Bottom-Right
      ].each do |cx, cy|
        6.times do |i|
          panel_surface.draw_rect_fill(GSDL::Rect.new(cx + i, cy + i, 1, 1), yellow_color)
          panel_surface.draw_rect_fill(GSDL::Rect.new(cx + 5 - i, cy + i, 1, 1), yellow_color)
        end
      end

      panel_texture = GSDL::Texture.from_surface(panel_surface)
      panel_surface.destroy

      panel_skin = GSDL::NinePatch.new(panel_texture, left: 12, right: 12, top: 12, bottom: 12)

      # 2. Create a programmatically generated 9-patch button texture (24x24)
      btn_surface = GSDL::Surface.new(24, 24)
      # Border
      btn_surface.fill(GSDL::Color.parse("#0f172a"))
      # Edge highlight (thicker)
      btn_surface.draw_rect_fill(GSDL::Rect.new(2, 2, 20, 20), GSDL::Color.parse("#6366f1"))
      # Center fill
      btn_surface.draw_rect_fill(GSDL::Rect.new(8, 8, 8, 8), GSDL::Color.parse("#4f46e5"))

      # Draw small cyan accent blocks in the corners
      cyan_color = GSDL::Color.parse("#22d3ee")
      btn_surface.draw_rect_fill(GSDL::Rect.new(2, 2, 4, 4), cyan_color)
      btn_surface.draw_rect_fill(GSDL::Rect.new(18, 2, 4, 4), cyan_color)
      btn_surface.draw_rect_fill(GSDL::Rect.new(2, 18, 4, 4), cyan_color)
      btn_surface.draw_rect_fill(GSDL::Rect.new(18, 18, 4, 4), cyan_color)

      btn_texture = GSDL::Texture.from_surface(btn_surface)
      btn_surface.destroy

      btn_skin = GSDL::NinePatch.new(btn_texture, left: 8, right: 8, top: 8, bottom: 8)

      # Build our UI
      @root_canvas = RootCanvas.new(800, 600) do |canvas|
        # Background fallback for the canvas
        # canvas.background_color = GSDL::Color.parse("#0f172a")

        vbox(
          spacing: 16,
          stretch: true,
          # flex: 0_u8,
          margin: Spacing.new(all: 64),
          padding: Spacing.new(all: 32)
        ) do |v|
          # Apply the NinePatch panel skin!
          v.background_skin = panel_skin

          text(
            text: "Nine-Patch Skin Demo",
            font_size: 16,
            color: GSDL::Color::Yellow,
            h_align: GSDL::HorizontalAlign::Center,
            flex: 0_u8
          )

          text(
            text: "This panel is rendered using a single 24x24 9-patch texture. The corners are kept at 1:1 scale (4px), while the borders scale along their respective axis and the center stretches bi-directionally.",
            font_size: 10,
            color: GSDL::Color::White,
            flex: 1_u8
          )

          hbox(
            spacing: 20,
            flex: 0_u8
          ) do
            button(
              text: "Okay",
              width: 140,
              height: 40,
              background_skin: btn_skin,
              padding: Spacing.new(horizontal: 10, vertical: 5)
            ) do
              puts "Okay button clicked!"
            end

            button(
              text: "Cancel",
              width: 140,
              height: 40,
              background_skin: btn_skin,
              padding: Spacing.new(horizontal: 10, vertical: 5)
            ) do
              puts "Cancel button clicked!"
            end
          end
        end
      end

      @event_handler = UIHandler.new(@root_canvas.not_nil!)
      GSDL::Game.instance.register_event_handler(@event_handler.not_nil!)
    end

    def update(dt : Float32)
      super(dt)
      @root_canvas.not_nil!.update(dt)
    end

    def draw(draw : GSDL::Draw)
      super(draw)
      @root_canvas.not_nil!.draw(draw)
    end

    def destroy
      if handler = @event_handler
        GSDL::Game.instance.unregister_event_handler(handler)
      end
    end
  end

  Game.new.run
end
