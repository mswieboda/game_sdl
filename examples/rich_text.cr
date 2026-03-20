require "../src/game_sdl"

alias Game = GSDL::Game

class MainScene < GSDL::Scene
  @rich_text : GSDL::RichText?

  def init
    text = "Hello! This is <c:red>RichText</c>.\n" \
           "We can use <c:#00FF00>Hex Colors</c>,\n" \
           "or <c:0,128,255>RGB Colors</c>.\n" \
           "Also supports <b>Bold</b> and <i>Italic</i>!\n" \
           "<b><i>Combined Style</i></b>"

    @rich_text = GSDL::RichText.new(
      text: text,
      x: Game.width // 2,
      y: Game.height // 2 + 50,
      origin: {0.5_f32, 0.5_f32},
      color: GSDL::Color::White,
      wrap_width: 600,
      align: GSDL::Font::Align::Center
    )
  end

  def draw(draw : GSDL::Draw)
    @rich_text.try &.draw(draw)

    instr = GSDL::Text.new(
      text: "GSDL RichText Demo",
      x: Game.width // 2,
      y: 50,
      origin: {0.5_f32, 0.5_f32},
      color: GSDL::Color::Cyan
    )
    instr.draw(draw)
  end
end

class MyGame < GSDL::Game
  def load_default_font
    "fonts/PressStart2P.ttf"
  end

  def init
    GSDL::Events.esc_exits = true
    push(MainScene.new)
  end
end

MyGame.new("RichText Demo", 800, 600).run
