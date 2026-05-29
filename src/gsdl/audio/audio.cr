require "sdl3"
require "sdl3/audio/mixer"

module GSDL
  class Audio
    getter file_path : String
    getter audio : LibSDL3Mixer::Audio*
    getter track : LibSDL3Mixer::Track*
    @category : String = "sfx"
    @is_owner : Bool = true

    def initialize(@file_path : String, @audio : LibSDL3Mixer::Audio*, @track : LibSDL3Mixer::Track*)
      # Default to SFX category
      self.category = "sfx"
    end

    def initialize(id : Symbol)
      referenced = AudioManager.get(id)
      @file_path = referenced.file_path
      @audio = referenced.audio
      @track = referenced.track
      @category = referenced.category
      @is_owner = false
    end

    # Plays the audio.
    # By default, it plays on its own dedicated track (best for persistent instances).
    # If already playing, it restarts from the beginning.
    #
    # If `overlap` is true, it uses the AudioManager's track pool to play a new
    # instance of this sound on a fresh channel, allowing multiple instances to layer.
    # Returns the channel ID used (or -1 for the dedicated channel).
    def play(loops : Int32 = 0, overlap : Bool = false) : Int32
      if overlap
        return play_overlapping(loops)
      end

      # Reset position to start if it was playing/paused
      LibSDL3Mixer.set_track_playback_position(@track, 0_i64)
      LibSDL3Mixer.set_track_loops(@track, loops)
      if LibSDL3Mixer.play_track(@track, 0_u32)
        return -1
      else
        raise "Failed to play track for '#{@file_path}': #{SDL3.get_error}"
      end
    end

    private def play_overlapping(loops : Int32 = 0) : Int32
      # Determine which range of tracks to search based on category
      is_music = ["music", "ambient"].includes?(category)
      range = is_music ? (24...32) : (0...24)

      # Find an available track in the designated range
      channel_id = -1
      AudioManager.tracks.each_with_index do |track, i|
        next unless range.includes?(i)
        unless LibSDL3Mixer.track_playing(track) || LibSDL3Mixer.track_paused(track)
          channel_id = i
          break
        end
      end

      if channel_id == -1
        STDERR.puts "Audio pool range (#{"Music" if is_music}#{"SFX" unless is_music}) exhausted! Could not play sound: #{@file_path}"
        return -1
      end

      track = AudioManager.tracks[channel_id]

      # Assign the audio data to the selected track
      unless LibSDL3Mixer.set_track_audio(track, @audio)
        STDERR.puts "Failed to set audio for track #{channel_id}: #{SDL3.get_error}"
        return -1
      end

      # Set properties
      LibSDL3Mixer.set_track_loops(track, loops)
      LibSDL3Mixer.tag_track(track, category.to_unsafe)

      # Play the track
      if LibSDL3Mixer.play_track(track, 0_u32)
        # Hold a strong reference to the asset during playback to prevent GC
        AudioManager.track_owners[channel_id] = self
        return channel_id
      else
        STDERR.puts "Failed to play sound on channel #{channel_id}: #{SDL3.get_error}"
        return -1
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
      return unless @is_owner

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
