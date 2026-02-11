require "../src/game_sdl"

module GameEx
  alias Mouse = GSDL::Mouse

  WIDTH = 800
  HEIGHT = 600

  # NOTE: This example embeds SDL3::IOStream objects
  #   directly into code during compilation, using macros.
  #   So assets are not required outside of the application after compiling
  #   and you can ship the application without separte asset files
  #   (takes longer to compile since it loads the assets during compliation)
  module Assets
    module Fonts
      PressStart = GSDL.embed_io_stream("assets/fonts/PressStart2P.ttf")
    end

    module Audio
      Sample = GSDL.embed_io_stream("assets/sfx/sample.wav")
    end

    module GFX
      Player = GSDL.embed_io_stream("assets/gfx/player.png")
    end
  end

  class Game < GSDL::Game
    def initialize
      super(title: "Embed Example", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_fonts
      GSDL::FontManager.load_from_memory("PressStart2P", Assets::Fonts::PressStart, GSDL::Font::DEFAULT_FONT_SIZE)
    end

    def load_audio
      GSDL::AudioManager.load_from_memory("sample_audio", Assets::Audio::Sample)
    end

    def load_textures
      GSDL::TextureManager.load_from_memory("player", Assets::GFX::Player)
    end
  end

  class SceneManager < GSDL::SceneManager
    getter start

    def initialize
      super
      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    enum AudioState
      Initial
      Playing
      Paused
      Stopped
    end

    @audio : GSDL::Audio
    @button_text : GSDL::Text
    @button_rect : SDL3::FRect
    @current_audio_state : AudioState

    @sprite : GSDL::AnimatedSprite

    def initialize
      super(:start)

      # audio button
      @audio = GSDL::AudioManager.get("sample_audio")

      @button_rect = SDL3::FRect.new(x: 50.0, y: 50.0, w: 200.0, h: 50.0)
      @current_audio_state = AudioState::Initial

      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)

      @button_text = GSDL::Text.new(text: "Play", color: color)
      @button_text.x = @button_rect.x + (@button_rect.w - @button_text.width) / 2
      @button_text.y = @button_rect.y + (@button_rect.h - @button_text.height) / 2

      # animation
      source_rect = GSDL::FRect.new(x: 0_f32, y: 0_f32, w: 128_f32, h: 128_f32)
      @sprite = GSDL::AnimatedSprite.new("player", 128, 128)
      @sprite.center(WIDTH, HEIGHT)
      @sprite.add("fire", (0..3).to_a, 12)
      @sprite.play("fire")
    end

    private def update_text(message : String)
      @button_text.text = message
      # Recalculate position after text change
      @button_text.x = @button_rect.x + (@button_rect.w - @button_text.width) / 2
      @button_text.y = @button_rect.y + (@button_rect.h - @button_text.height) / 2
    end

    def update(dt : Float32)
      @sprite.update(dt)

      # Handle button click
      if Mouse.just_pressed?(Mouse::ButtonLeft)
        mouse_x, mouse_y = Mouse.position

        if mouse_x >= @button_rect.x && mouse_x <= (@button_rect.x + @button_rect.w) &&
           mouse_y >= @button_rect.y && mouse_y <= (@button_rect.y + @button_rect.h)
          case @current_audio_state
          when AudioState::Initial, AudioState::Stopped
            @audio.play
            @current_audio_state = AudioState::Playing
            update_text("Pause")
          when AudioState::Paused
            @audio.resume
            @current_audio_state = AudioState::Playing
            update_text("Pause")
          when AudioState::Playing
            @audio.pause
            @current_audio_state = AudioState::Paused
            update_text("Unpause")
          end
        end
      end

      # Automatic state transitions (e.g., stopping after audio finishes)
      if @current_audio_state == AudioState::Playing
        if @audio.finished?
          @audio.stop
          @current_audio_state = AudioState::Stopped
          update_text("Play")
        end
      end
    end

    def draw(renderer : GSDL::Renderer)
      # button
      renderer.draw_color = {100_u8, 100_u8, 100_u8, 255_u8}
      renderer.fill_rect(@button_rect)
      @button_text.draw(renderer)

      # animation
      @sprite.draw(renderer)
    end
  end

  Game.new.run
end
