require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def initialize
      super(title: "Audio Pooling Example")
    end

    def init
      GSDL::Events.esc_exits = true
      
      # Register fonts
      GSDL::FontManager.register({
        default: "PressStart2P.ttf"
      })

      # Register the audio
      GSDL::AudioManager.register({
        ding: "ding.wav"
      })
      GSDL::AudioManager.register({
        theme: "race_car.wav"
      }, category: "music")

      # Load them explicitly
      GSDL::AudioManager.get(:ding)
      GSDL::AudioManager.get(:theme)

      GSDL::Game.push(PoolingScene.new)
    end
  end

  class PoolingScene < GSDL::Scene
    @played_count = 0
    @status_text : GSDL::Text
    @timer : GSDL::Timer
    @theme_audio : GSDL::Audio
    @ding_audio : GSDL::Audio

    MAX_COUNT = 10

    def initialize
      super(:pooling)
      @status_text = GSDL::Text.new(text: "Audio Pooling Test: Ready", x: 10, y: 10)
      @timer = GSDL::Timer.new(0.5.seconds)
      @timer.start
      @theme_audio = GSDL::Audio.new(:theme)
      @ding_audio = GSDL::Audio.new(:ding)
    end

    def update(dt : Float32)
      if @played_count < MAX_COUNT && @timer.done?
        # Use GSDL::Audio instances to play on pooled channels (overlapping)
        channel_theme = @theme_audio.play(overlap: true)
        puts "Played :theme (overlap) on channel #{channel_theme}"

        # Demonstrating dedicated playback (restarts instead of overlapping)
        # We only do this once to not drown out the overlapping sounds
        if @played_count <= 0
          channel_ding = @ding_audio.play
          puts "Played :ding (dedicated) on channel #{channel_ding}"
        end

        @played_count += 1
        @status_text.text = "Audio Pooling Test: Played #{@played_count} instances"
        @timer.restart
      end
      if @played_count >= MAX_COUNT && @timer.done?
        puts "Test completed. Closing."
        exit
      end
    end

    def draw(draw : GSDL::Draw)
      @status_text.draw(draw)
    end
  end

  Game.new.run
end
