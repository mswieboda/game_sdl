require "sdl3"
require "sdl3/audio/mixer"

module GSDL
  class Audio
    @file_path : String
    @audio : LibSDL3Mixer::Audio*
    @track : LibSDL3Mixer::Track*

    def initialize(@file_path : String, @audio : LibSDL3Mixer::Audio*, @track : LibSDL3Mixer::Track*)
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
      # NOTE: LibSDL3Mixer.track_playing returns false if the track is stopped
      # So, if not playing and not paused, it's finished or stopped.
      # When stopped, it's considered finished.
      !LibSDL3Mixer.track_playing(@track) && !LibSDL3Mixer.track_paused(@track)
    end

    def destroy
      if @track
        LibSDL3Mixer.destroy_track(@track)
        @track = Pointer(Void).null
      end
      if @audio
        LibSDL3Mixer.destroy_audio(@audio)
        @audio = Pointer(Void).null
      end
    end
  end
end
