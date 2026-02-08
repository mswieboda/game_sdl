require "sdl3"
require "sdl3/audio/mixer"

module GSDL
  class Audio
    @@mixer : LibSDL3Mixer::Mixer* = Pointer(Void).null

    @file_path : String
    @audio : LibSDL3Mixer::Audio*
    @track : LibSDL3Mixer::Track*

    def self.init_mixer
      return if @@mixer

      # Initialize SDL_mixer
      unless SDL3::Mixer.init
        raise "Failed to initialize SDL_mixer: #{SDL3.get_error}"
      end

      # Create mixer device, letting SDL_mixer determine the best audio format
      @@mixer = LibSDL3Mixer.create_mixer_device(LibSDL3::AUDIO_DEVICE_DEFAULT_PLAYBACK, Pointer(LibSDL3::AudioSpec).null)
      if @@mixer.null?
        raise "Failed to create SDL_mixer: #{SDL3.get_error}"
      end
    end

    def self.quit_mixer
      if @@mixer
        LibSDL3Mixer.destroy_mixer(@@mixer)
        @@mixer = Pointer(Void).null
      end
      SDL3::Mixer.quit
    end

    def initialize(@file_path : String)
      self.class.init_mixer

      @audio = LibSDL3Mixer.load_audio(@@mixer, @file_path.to_unsafe, true)
      if @audio.null?
        self.class.quit_mixer # If loading fails, decrease the count and possibly quit the mixer
        raise "Failed to load audio file '#{@file_path}': #{SDL3.get_error}"
      end

      @track = LibSDL3Mixer.create_track(@@mixer)
      if @track.null?
        LibSDL3Mixer.destroy_audio(@audio)
        self.class.quit_mixer # If track creation fails, decrease the count and possibly quit the mixer
        raise "Failed to create track for '#{@file_path}': #{SDL3.get_error}"
      end

      unless LibSDL3Mixer.set_track_audio(@track, @audio)
        LibSDL3Mixer.destroy_track(@track)
        LibSDL3Mixer.destroy_audio(@audio)
        self.class.quit_mixer
        raise "Failed to set audio to track for '#{@file_path}': #{SDL3.get_error}"
      end
    end

    def play
      unless LibSDL3Mixer.play_track(@track, 0_u32)
        raise "Failed to play track for '#{@file_path}': #{SDL3.get_error}"
      end
    end

    def pause
      unless LibSDL3Mixer.pause_track(@track)
        raise "Failed to pause track for '#{@file_path}': #{SDL3.get_error}"
      end
    end

    def resume
      unless LibSDL3Mixer.resume_track(@track)
        raise "Failed to resume track for '#{@file_path}': #{SDL3.get_error}"
      end
    end

    def stop
      unless LibSDL3Mixer.stop_track(@track, 0)
        raise "Failed to stop track for '#{@file_path}': #{SDL3.get_error}"
      end
    end

    def playing? : Bool
      LibSDL3Mixer.track_playing(@track)
    end

    def paused? : Bool
      LibSDL3Mixer.track_paused(@track)
    end

    def finished? : Bool
      !playing? && !paused?
    end

    def destroy
      if @track
        LibSDL3Mixer.destroy_track(@track)
        @track = nil
      end
      if @audio
        LibSDL3Mixer.destroy_audio(@audio)
        @audio = nil
      end
      self.class.quit_mixer
    end
  end
end