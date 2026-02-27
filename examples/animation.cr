require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Animation Ex", width: WIDTH, height: HEIGHT)
    end

    def init
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_textures
      [{"player", "gfx/skeleton.png"}]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super

      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @sprite : GSDL::AnimatedSprite
    @text : GSDL::Text
    @text_animation : GSDL::Text
    @animations = ["idle", "walk", "crouch", "hit", "jump"]
    @animation_index = 0

    def initialize
      super(:start)

      origin = {0.5_f32, 0.5_f32}

      @sprite = GSDL::AnimatedSprite.new("player", 32, 64, origin: origin)
      @sprite.center(width: WIDTH, height: HEIGHT)

      @sprite.add("idle", [0], 8)
      @sprite.add("walk", (1..6).to_a, 8)
      @sprite.add("crouch", (7..9).to_a, 4, loops: false)
      @sprite.add("hit", (10..12).to_a, 4, loops: false)
      @sprite.add("jump", (17..19).to_a, 4, loops: false)
      @sprite.play("idle")

      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)
      @text = GSDL::Text.new(text: "LEFT/RIGHT or A/D to toggle animations!", origin: origin, color: color)
      @text_animation = GSDL::Text.new(text: "idle", origin: origin, color: color)

      # Center the text
      @text.center(width: WIDTH, height: 96)
      @text_animation.center(width: WIDTH, height: HEIGHT + 256)
    end

    def update(dt : Float32)
      @sprite.update(dt)

      if Keys.just_pressed?([Keys::A, Keys::Left])
        @animation_index -= 1
        @animation_index = @animations.size - 1 if @animation_index < 0
        change_animation
      elsif Keys.just_pressed?([Keys::D, Keys::Right])
        @animation_index += 1
        @animation_index = 0 if @animation_index >= @animations.size
        change_animation
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
      @text_animation.draw(draw)

      @sprite.draw(draw)
    end

    def change_animation
      animation = @animations[@animation_index]
      @sprite.play(animation)
      @text_animation.text = animation
      @text_animation.center(width: WIDTH, height: HEIGHT + 256)
    end
  end

  Game.new.run
end
