require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Global Sound Settings Example")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(SettingsScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_audio
      # Load SFX and Music categories
      # Note: Asset path is prepended in debug mode, so sfx/ding.wav becomes assets/sfx/ding.wav
      [
        {"sfx_ding", "sfx/ding.wav", "sfx"},
        {"music_race", "sfx/race_car.wav", "music"}
      ]
    end
  end

  class SettingsScene < GSDL::Scene
    @sfx : GSDL::Audio
    @music : GSDL::Audio
    @master_bar : GSDL::ProgressBar
    @sfx_bar : GSDL::ProgressBar
    @music_bar : GSDL::ProgressBar
    @selected_index : Int32 = 0
    @labels : Array(GSDL::Text)
    @values : Array(GSDL::Text)
    @title_text : GSDL::Text

    def initialize
      super(:settings)
      @sfx = GSDL::AudioManager.get("sfx_ding")
      @music = GSDL::AudioManager.get("music_race")
      @music.looping = -1 # Loop the music

      @master_bar = GSDL::ProgressBar.new(x: 288, y: 96, width: 192, height: 16, value: 1.0)
      @sfx_bar = GSDL::ProgressBar.new(x: 288, y: 144, width: 192, height: 16, value: 1.0)
      @music_bar = GSDL::ProgressBar.new(x: 288, y: 192, width: 192, height: 16, value: 1.0)

      GSDL::SoundSettings.master_volume = 1.0_f32
      GSDL::SoundSettings.set_volume("sfx", 1.0_f32)
      GSDL::SoundSettings.set_volume("music", 1.0_f32)

      @title_text = GSDL::Text.new(
        text: "Global Sound Settings\nSPACE: SFX | M: Music\nTAB: Cycle | UP/DOWN: Adjust",
        x: Game.width // 2,
        y: 8,
        origin: {0.5_f32, 0_f32},
        h_align: GSDL::HorizontalAlign::Center
      )

      label_names = ["Master Volume", "SFX Volume", "Music Volume"]
      @labels = label_names.map_with_index do |name, i|
        GSDL::Text.new(text: name, x: 32, y: 96 + i * 48)
      end

      @values = (0..2).map do |i|
        GSDL::Text.new(text: "", x: 512, y: 96 + i * 48)
      end
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Tab)
        @selected_index = (@selected_index + 1) % 3
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        @sfx.play
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::M)
        if @music.playing?
          @music.stop
        else
          @music.play
        end
      end

      # Adjust selected setting
      change = 0.0_f32
      if GSDL::Keys.pressed?(GSDL::Keys::Up)
        change = 0.01_f32
      elsif GSDL::Keys.pressed?(GSDL::Keys::Down)
        change = -0.01_f32
      end

      case @selected_index
      when 0 # Master
        GSDL::SoundSettings.master_volume = (GSDL::SoundSettings.master_volume + change).clamp(0.0_f32, 2.0_f32)
        @master_bar.value = GSDL::SoundSettings.master_volume / 2.0_f32
      when 1 # SFX
        val = (GSDL::SoundSettings.get_volume("sfx") + change).clamp(0.0_f32, 2.0_f32)
        GSDL::SoundSettings.set_volume("sfx", val)
        @sfx_bar.value = val / 2.0_f32
      when 2 # Music
        val = (GSDL::SoundSettings.get_volume("music") + change).clamp(0.0_f32, 2.0_f32)
        GSDL::SoundSettings.set_volume("music", val)
        @music_bar.value = val / 2.0_f32
      end

      # Update text colors and values
      @labels.each_with_index do |text, i|
        text.color = i == @selected_index ? GSDL.color(r: 255, g: 255) : GSDL.color(r: 255, g: 255, b: 255)
        text.text = (i == @selected_index ? "> " : "  ") + text.text.gsub(/^> |^  /, "")
      end

      @values[0].text = "Master: #{(GSDL::SoundSettings.master_volume * 100).round}%"
      @values[1].text = "SFX: #{(GSDL::SoundSettings.get_volume("sfx") * 100).round}%"
      @values[2].text = "Music: #{(GSDL::SoundSettings.get_volume("music") * 100).round}%"
    end

    def draw(draw : GSDL::Draw)
      @title_text.draw(draw)
      @labels.each(&.draw(draw))
      @values.each(&.draw(draw))
      @master_bar.draw(draw)
      @sfx_bar.draw(draw)
      @music_bar.draw(draw)
    end
  end

  Game.new.run
end
