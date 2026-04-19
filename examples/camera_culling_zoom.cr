require "../src/game_sdl"

# This example demonstrates and verifies the culling logic when zooming.
# Previously, objects were incorrectly culled when zooming out (scale < 1.0).
# Now, the DrawCommand#on_screen? methods correctly account for scale.

class CameraCullingZoomGame < GSDL::Game
  def initialize
    super(title: "Camera Culling Zoom Example")
  end

  def init
    GSDL::Events.esc_exits = true
    GSDL::Game.push(MainScene.new)
  end

  def load_default_font
    "fonts/PressStart2P.ttf"
  end
end

class MainScene < GSDL::Scene
  @zoom : Float32 = 1.0_f32

  def initialize
    super(:main)

    h = GSDL::HUD.new

    h << GSDL::HUDText.new(
      text_data_template: "{zoom_info}",
      anchor: GSDL::Anchor::TopLeft,
      offset_x: 10,
      offset_y: 10,
      color: GSDL::Color::White
    )

    h << GSDL::HUDText.new(
      text_data_template: "{cmd_count}",
      anchor: GSDL::Anchor::TopLeft,
      offset_x: 10,
      offset_y: 40,
      color: GSDL::Color::White
    )

    h << GSDL::HUDText.new(
      text: "Red box is at x=1000.\n\nShould be visible when Zoom < 0.8",
      anchor: GSDL::Anchor::TopLeft,
      offset_x: 10,
      offset_y: 70,
      color: GSDL::Color::White
    )

    self.hud = h
  end

  def update(dt : Float32)
    super(dt)

    if GSDL::Keys.pressed?(GSDL::Keys::E)
      @zoom += 1.0_f32 * dt
    end
    if GSDL::Keys.pressed?(GSDL::Keys::Q)
      @zoom -= 1.0_f32 * dt
      @zoom = 0.1_f32 if @zoom < 0.1_f32
    end
    if GSDL::Keys.just_pressed?(GSDL::Keys::R)
      @zoom = 1.0_f32
    end

    GSDL::Data.set("zoom_info", "Zoom: #{sprintf("%.2f", @zoom)} (Q/E to zoom, R to reset)")
    # Note: command_count is from the previous frame in update
    GSDL::Data.set("cmd_count", "Draw commands: #{GSDL::Game.draw.command_count}")
  end

  def draw(draw : GSDL::Draw)
    draw.scale = @zoom

    # Draw a rectangle that is outside 800x600 but should be visible when zooming out.
    # e.g. at x=1000, zoom=0.5, it should be at 500px on screen.
    draw.rect_fill(
      rect: GSDL::FRect.new(x: 1000, y: 100, w: 100, h: 100),
      color: GSDL::Color::Red
    )

    # Draw a rectangle that is at the edge
    draw.rect_fill(
      rect: GSDL::FRect.new(x: 750, y: 100, w: 100, h: 100),
      color: GSDL::Color::Green
    )

    # HUD is drawn automatically by super(draw) if we call it,
    # or GSDL::Scene#draw usually calls it.
    super(draw)
  end
end

CameraCullingZoomGame.new.run
