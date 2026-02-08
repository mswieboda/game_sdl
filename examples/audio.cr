require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias Mouse = GSDL::Mouse

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Text Example", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_fonts
      GSDL::FontManager.load(GSDL::Font::DEFAULT_FONT_PATH, GSDL::Font::DEFAULT_FONT_SIZE)
    end

    def load_audio
      GSDL::AudioManager.load("sample_audio", "./assets/sfx/sample.wav")
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
    @text : GSDL::Text
    @button_rect : LibSDL3::FRect
    @button_stop_rect : LibSDL3::FRect
    @current_audio_state : AudioState
    @audio_start_tick : UInt64 = 0_u64

    def initialize
      super(:start)

      @button_rect = LibSDL3::FRect.new(x: 50.0, y: 50.0, w: 200.0, h: 50.0)
      @button_stop_rect = LibSDL3::FRect.new(x: 50.0, y: 150.0, w: 200.0, h: 50.0)
      @current_audio_state = AudioState::Initial

      @audio = GSDL::AudioManager.get("sample_audio")

      color = GSDL::Color.new(r: 0, g: 255, b: 0, a: 255)

      @text = GSDL::Text.new(text: "Play", color: color)
      @text.x = @button_rect.x + (@button_rect.w - @text.width) / 2
      @text.y = @button_rect.y + (@button_rect.h - @text.height) / 2

      @text_stop = GSDL::Text.new(text: "Stop", color: color)
      @text_stop.x = @button_stop_rect.x + (@button_stop_rect.w - @text_stop.width) / 2
      @text_stop.y = @button_stop_rect.y + (@button_stop_rect.h - @text_stop.height) / 2

      update_text("Play")
    end

    private def update_text(message : String)
      @text.text = message
      # Recalculate position after text change
      @text.x = @button_rect.x + (@button_rect.w - @text.width) / 2
      @text.y = @button_rect.y + (@button_rect.h - @text.height) / 2
    end

    def update(dt : Float32)
      if Keys.pressed?(Keys::Escape)
        @exit = true
        return
      end

      # Handle button click
      if Mouse.just_pressed?(Mouse::ButtonLeft)
        mouse_x, mouse_y = Mouse.position

        if mouse_x >= @button_rect.x && mouse_x <= (@button_rect.x + @button_rect.w) &&
           mouse_y >= @button_rect.y && mouse_y <= (@button_rect.y + @button_rect.h)
          case @current_audio_state
          when AudioState::Initial, AudioState::Stopped
            @audio.play
            @current_audio_state = AudioState::Playing
            @audio_start_tick = SDL3.get_ticks
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
        elsif mouse_x >= @button_stop_rect.x && mouse_x <= (@button_stop_rect.x + @button_stop_rect.w) &&
           mouse_y >= @button_stop_rect.y && mouse_y <= (@button_stop_rect.y + @button_stop_rect.h)
          @audio.stop
          @current_audio_state = AudioState::Stopped
          update_text("Play")
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

    def draw(renderer : SDL3::Renderer)
      # Draw button
      renderer.draw_color = {100_u8, 100_u8, 100_u8, 255_u8}
      renderer.fill_rect(@button_rect)
      renderer.fill_rect(@button_stop_rect)

      # Draw text
      @text.draw(renderer)
      @text_stop.draw(renderer)
    end

    def destroy
      @text.destroy
      super
    end
  end

  Game.new.run
end
