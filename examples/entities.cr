require "../src/game_sdl"

alias Game = GSDL::Game

class Player < GSDL::Entity
  @sprite : GSDL::AnimatedSprite
  @label : GSDL::RichText

  def initialize(x, y)
    @x = x.to_f32
    @y = y.to_f32

    # Child sprite at relative {0, 0}
    @sprite = GSDL::AnimatedSprite.new("player", width: 32, height: 64, origin: {0.5_f32, 0.5_f32})
    @sprite.add("walk", (1..6).to_a, 8)
    @sprite.play("walk")

    # Child label at relative {0, -40} (above head)
    @label = GSDL::RichText.new(
      text: "<c:red>HP: 100/100</c>",
      y: -40,
      origin: {0.5_f32, 0.5_f32}
    )

    add_child(@sprite)
    add_child(@label)
  end

  def update(dt : Float32) : Bool
    return false unless super(dt)

    # Move parent
    if GSDL::Keys.pressed?(GSDL::Keys::Left)
      @x -= 200 * dt
      @sprite.flip_h = true
    elsif GSDL::Keys.pressed?(GSDL::Keys::Right)
      @x += 200 * dt
      @sprite.flip_h = false
    end

    true
  end
end

class MainScene < GSDL::Scene
  def init
    # Add player to scene
    add_child(Player.new(Game.width // 2, Game.height // 2))

    # Add a standalone sprite to scene
    barrel = GSDL::Sprite.new("barrel", x: 100, y: 100)
    add_child(barrel)
  end

  # Default Scene#update and Scene#draw now handle children!
  # No need to override them unless we want custom logic.
end

class MyGame < GSDL::Game
  def load_textures
    [
      {"player", "gfx/skeleton.png"},
      {"barrel", "gfx/barrel.png"}
    ]
  end

  def load_default_font
    "fonts/PressStart2P.ttf"
  end

  def init
    GSDL::Events.esc_exits = true
    push(MainScene.new)
  end
end

MyGame.new("Entities Example", 800, 600).run
