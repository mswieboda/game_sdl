require "../src/game_sdl"

alias Game = GSDL::Game

class MainScene < GSDL::Scene
  @message : GSDL::Message?
  @rich_text : GSDL::RichTextTyped?

  def init
    text = "Hello! This is <c:red>RichTextTyped</c>.\n" \
           "It supports <c:#00FF00>typewriter effects</c>,\n" \
           "while maintaining <b>Bold</b> and <i>Italic</i>.\n" \
           "Colors: <c:blue>Blue</c>, <c:yellow>Yellow</c>, <c:magenta>Magenta</c>.\n" \
           "Press SPACE to restart."

    @rich_text = GSDL::RichTextTyped.new(
      text: text,
      color: GSDL::Color::White,
      wrap_width: 600,
      align: GSDL::Font::Align::Center,
      types_per_second: 5,
      type: GSDL::RichTextTyped::Type::Word
    )

    @message = GSDL::Message.new(
      text: @rich_text.not_nil!,
      x: Game.width // 2,
      y: Game.height // 2 + 50,
      origin: {0.5_f32, 0.5_f32},
      bg_color: GSDL::Color::DarkGray,
      border_radius: 16
    )
  end

  def update(dt : Float32)
    @message.try &.update(dt)

    if GSDL::Keys.pressed?(GSDL::Keys::Space)
      @rich_text.try &.restart
    end
  end

  def draw(draw : GSDL::Draw)
    @message.try &.draw(draw)

    instr = GSDL::TextOld.new(
      text: "GSDL RichTextTyped Demo",
      x: Game.width // 2,
      y: 50,
      origin: {0.5_f32, 0.5_f32},
      color: GSDL::Color::Cyan
    )
    instr.draw(draw)
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
