require "../src/game_sdl"

module GameEx
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
      GSDL::FontManager.load_default("fonts/PressStart2P.ttf")
    end

    def load_audio
      GSDL::AudioManager.load("race_car_audio", "sfx/race_car.wav")
    end
  end

  class SceneManager < GSDL::SceneManager
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
    @button_rect : GSDL::FRect
    @button_stop_rect : GSDL::FRect
    @current_audio_state : AudioState
    @audio_start_tick : UInt64 = 0_u64

    def initialize
      super(:start)

      @button_rect = GSDL::FRect.new(x: 50.0, y: 50.0, w: 200.0, h: 50.0)
      @button_stop_rect = GSDL::FRect.new(x: 50.0, y: 150.0, w: 200.0, h: 50.0)
      @current_audio_state = AudioState::Initial

      @audio = GSDL::AudioManager.get("race_car_audio")

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
      # Handle button click
      if Mouse.just_pressed?(Mouse::ButtonLeft)
        mouse_x, mouse_y = Mouse.position

        if mouse_x >= @button_rect.x && mouse_x <= (@button_rect.x + @button_rect.w) &&
           mouse_y >= @button_rect.y && mouse_y <= (@button_rect.y + @button_rect.h)
          case @current_audio_state
          when AudioState::Initial, AudioState::Stopped
            @audio.play
            @current_audio_state = AudioState::Playing
            @audio_start_tick = GSDL.ticks
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

    def draw(draw : GSDL::Draw)
      # Draw button
      draw.color = GSDL.color_all(100)
      draw.rect_filled(@button_rect)
      draw.rect_filled(@button_stop_rect)

      # Draw text
      @text.draw(draw)
      @text_stop.draw(draw)
    end

    def destroy
      @text.destroy
      super
    end
  end

  Game.new.run
end
