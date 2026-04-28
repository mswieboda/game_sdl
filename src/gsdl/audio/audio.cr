require "sdl3"
require "sdl3/audio/mixer"

module GSDL
  class Audio
    @file_path : String
    @audio : LibSDL3Mixer::Audio*
    @track : LibSDL3Mixer::Track*
    @category : String = "sfx"

    def initialize(@file_path : String, @audio : LibSDL3Mixer::Audio*, @track : LibSDL3Mixer::Track*)
      # Default to SFX category
      self.category = "sfx"
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
      !LibSDL3Mixer.track_playing(@track) && !LibSDL3Mixer.track_paused(@track)
    end

    # --- New Features ---

    def volume : Float32
      LibSDL3Mixer.get_track_gain(@track)
    end

    def volume=(value : Float32)
      LibSDL3Mixer.set_track_gain(@track, value)
    end

    def pitch : Float32
      LibSDL3Mixer.get_track_frequency_ratio(@track)
    end

    def pitch=(value : Float32)
      LibSDL3Mixer.set_track_frequency_ratio(@track, value)
    end

    def looping : Int32
      LibSDL3Mixer.get_track_loops(@track)
    end

    def looping=(value : Int32)
      LibSDL3Mixer.set_track_loops(@track, value)
    end

    def pan=(value : Float32)
      # value should be -1.0 (left) to 1.0 (right)
      left = 1.0_f32
      right = 1.0_f32

      if value < 0
        right = 1.0_f32 + value
      elsif value > 0
        left = 1.0_f32 - value
      end

      gains = LibSDL3Mixer::StereoGains.new(left: left, right: right)
      LibSDL3Mixer.set_track_stereo(@track, pointerof(gains))
    end

    def category : String
      @category
    end

    def category=(tag : String)
      @category = tag
      LibSDL3Mixer.tag_track(@track, tag.to_unsafe)
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
