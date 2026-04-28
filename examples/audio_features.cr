require "../src/game_sdl"

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Audio Features Example")
    end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(AudioScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_audio
      [{"race_car", "sfx/race_car.wav"}]
    end
  end

  class AudioScene < GSDL::Scene
    @audio : GSDL::Audio
    @volume_bar : GSDL::ProgressBar
    @pitch_bar : GSDL::ProgressBar
    @pan_bar : GSDL::ProgressBar
    @selected_index : Int32 = 0
    @labels : Array(GSDL::Text)
    @values : Array(GSDL::Text)
    @title_text : GSDL::Text
    @loop_status : GSDL::Text
    @looping : Bool = false
    @pan : Float32 = 0.0_f32

    def initialize
      super(:audio)
      @audio = GSDL::AudioManager.get("race_car")
      @audio.looping = 0

      @volume_bar = GSDL::ProgressBar.new(x: 300, y: 100, width: 200, height: 20, value: 0.5)
      @pitch_bar = GSDL::ProgressBar.new(x: 300, y: 150, width: 200, height: 20, value: 0.5) # 0.5 maps to 1.0 pitch
      @pan_bar = GSDL::ProgressBar.new(x: 300, y: 200, width: 200, height: 20, value: 0.5)   # 0.5 maps to 0.0 pan

      @audio.volume = 0.5_f32
      @audio.pitch = 1.0_f32
      @audio.pan = 0.0_f32

      @title_text = GSDL::Text.new(
        text: "Audio Features\nSPACE: Play | S: Stop\nTAB: Cycle | UP/DOWN: Adjust",
        x: Game.width // 2,
        y: 8,
        origin: {0.5_f32, 0_f32},
        align: GSDL::Font::Align::Center
      )
      
      label_names = ["Volume", "Pitch", "Pan", "Loop (Off/Inf)"]
      @labels = label_names.map_with_index do |name, i|
        GSDL::Text.new(text: name, x: 32, y: 100 + i * 50)
      end

      @values = (0..2).map do |i|
        GSDL::Text.new(text: "", x: 520, y: 100 + i * 50)
      end

      @loop_status = GSDL::Text.new(text: "OFF", x: 360, y: 250)
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Tab)
        @selected_index = (@selected_index + 1) % 4
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        @audio.play
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::S)
        @audio.stop
      end

      # Adjust selected setting
      change = 0.0_f32
      if GSDL::Keys.pressed?(GSDL::Keys::Up)
        change = 0.01_f32
      elsif GSDL::Keys.pressed?(GSDL::Keys::Down)
        change = -0.01_f32
      end

      case @selected_index
      when 0 # Volume
        @audio.volume = (@audio.volume + change).clamp(0.0_f32, 1.0_f32)
        @volume_bar.value = @audio.volume
      when 1 # Pitch
        # Map 0.0-1.0 bar to 0.5-2.0 pitch
        current_val = (@audio.pitch - 0.5_f32) / 1.5_f32
        new_val = (current_val + change).clamp(0.0_f32, 1.0_f32)
        @audio.pitch = 0.5_f32 + (new_val * 1.5_f32)
        @pitch_bar.value = new_val
      when 2 # Pan
        @pan = (@pan + change).clamp(-1.0_f32, 1.0_f32)
        @audio.pan = @pan
        @pan_bar.value = (@pan + 1.0_f32) / 2.0_f32
      when 3 # Loop
        if GSDL::Keys.just_pressed?(GSDL::Keys::Up) || GSDL::Keys.just_pressed?(GSDL::Keys::Down)
          @looping = !@looping
          @audio.looping = @looping ? -1 : 0
        end
      end

      # Update text colors and values
      @labels.each_with_index do |text, i|
        text.color = i == @selected_index ? GSDL.color(r: 255, g: 255) : GSDL.color(r: 255, g: 255, b: 255)
        text.text = (i == @selected_index ? "> " : "  ") + text.text.gsub(/^> |^  /, "")
      end

      @values[0].text = "Vol: #{@audio.volume.round(2)}"
      @values[1].text = "Pitch: #{@audio.pitch.round(2)}"
      @values[2].text = "Pan: #{@pan.round(2)}"
      @loop_status.text = @looping ? "INFINITE" : "OFF"
    end

    def draw(draw : GSDL::Draw)
      @title_text.draw(draw)
      @labels.each(&.draw(draw))
      @values.each(&.draw(draw))
      @volume_bar.draw(draw)
      @pitch_bar.draw(draw)
      @pan_bar.draw(draw)
      @loop_status.draw(draw)
    end
  end

  Game.new.run
end
