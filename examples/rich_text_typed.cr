require "../src/game_sdl"

alias Game = GSDL::Game

class MainScene < GSDL::Scene
  @rich_text : GSDL::RichTextTyped

  def initialize
    super(:main)

    text = "Hello! This is <c:red>RichTextTyped</c>.\n" \
           "It supports <c:#00FF00>typewriter effects</c>,\n" \
           "with styles <b>Bold</b> and <i>Italic</i>.\n" \
           "Colors: <c:blue>Blue</c>, <c:yellow>Yellow</c>, <c:magenta>Magenta</c>.\n" \
           "Press SPACE to restart."
    @rich_text = GSDL::RichTextTyped.new(
      text: text,
      x: 32,
      y: 64,
      color: GSDL::Color::White,
      wrap_width: 600,
      align: GSDL::Font::Align::Center,
      types_per_second: 5,
      type: GSDL::RichTextTyped::Type::Word
    )
  end

  def update(dt : Float32)
    @rich_text.update(dt)

    if GSDL::Keys.pressed?(GSDL::Keys::Space)
      @rich_text.restart
    end
  end

  def draw_screen_overlay(draw : GSDL::Draw)
    @rich_text.draw(draw)
  end
end

class MyGame < GSDL::Game
  def load_default_font_old
    "fonts/PressStart2P.ttf"
  end

  def init
    GSDL::Events.esc_exits = true
    push(MainScene.new)
  end
end

MyGame.new("RichTextTyped Demo", 800, 600).run
