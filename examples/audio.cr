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
      GSDL::Events.esc_exits = true
      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_audio
      [{"race_car_audio", "sfx/race_car.wav"}]
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
    @button : GSDL::Button
    @button_stop : GSDL::Button
    @current_audio_state : AudioState = AudioState::Initial
    @audio_start_tick : UInt64 = 0_u64

    def initialize
      super(:start)

      color = GSDL.color(g: 255)
      @button = GSDL::Button.new(
        text: "Play",
        x: 50,
        y: 50,
        width: 200,
        height: 50,
        on_click: -> on_click_play(String)
      )
      @button_stop = GSDL::Button.new(
        text: "Stop",
        x: 50,
        y: 150,
        width: 200,
        height: 50,
        on_click: -> on_click_stop(String)
      )

      @audio = GSDL::AudioManager.get("race_car_audio")

      update_text("Play")
    end

    private def update_text(message : String)
      @button.text = message
    end

    private def on_click_play(_text : String)
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
    end

    private def on_click_stop(_text : String)
      @audio.stop
      @current_audio_state = AudioState::Stopped
      update_text("Play")
    end

    def update(dt : Float32)
      @button.update(dt)
      @button_stop.update(dt)

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
      @button.draw(draw)
      @button_stop.draw(draw)
    end
  end

  Game.new.run
end
