require "sdl3"

module GSDL
  class Audio
    getter? paused : Bool = false

    @file_path : String
    @spec : LibSDL3::AudioSpec
    @audio_buf : Pointer(UInt8)
    @audio_len : UInt32
    @audio_stream : LibSDL3::AudioStream*

    # TODO: refactor loading to AudioManager like TextureManager or FontManager
    # A class-level hash to store loaded audio instances, preventing duplicate loading.
    @@loaded_audio = Hash(String, Audio).new

    def self.load(file_path) : Audio
      if @@loaded_audio.has_key?(file_path)
        return @@loaded_audio[file_path]
      end

      audio = new(file_path)
      @@loaded_audio[file_path] = audio
      audio
    end

    private def initialize(@file_path : String)
      @spec = uninitialized LibSDL3::AudioSpec
      @audio_buf = Pointer(UInt8).null
      @audio_len = 0_u32

      unless LibSDL3.load_wav(@file_path, pointerof(@spec), pointerof(@audio_buf), pointerof(@audio_len))
        raise "Failed to load WAV file '#{@file_path}': #{SDL3.get_error}"
      end

      @audio_stream = LibSDL3.open_audio_device_stream(LibSDL3::AUDIO_DEVICE_DEFAULT_PLAYBACK, pointerof(@spec), nil, nil)
      if @audio_stream.null?
        LibSDL3.free(@audio_buf)
        raise "Failed to open audio device stream for '#{@file_path}': #{SDL3.get_error}"
      end
    end

    def play
      if @audio_stream.null?
        raise "Attempted to play a destroyed audio stream for '#{@file_path}'"
      end

      # TODO: needs work to restart from beginning if it's ever been paused
      #   if it's been paused and done playing, it won't restart
      #   need to use duration_ms in combination with pausing somehow
      unless paused?
        # Clear any previous data in the stream before adding new data
        LibSDL3.clear_audio_stream(@audio_stream)

        unless LibSDL3.put_audio_stream_data(@audio_stream, @audio_buf, @audio_len)
          raise "Failed to put audio stream data for '#{@file_path}': #{SDL3.get_error}"
        end
      end

      unless LibSDL3.resume_audio_stream_device(@audio_stream)
        raise "Failed to resume audio stream device for '#{@file_path}': #{SDL3.get_error}"
      end
    end

    def pause
      if @audio_stream.null?
        return # Already destroyed or not initialized
      end
      @paused = LibSDL3.pause_audio_stream_device(@audio_stream)
    end

    def stop
      if @audio_stream.null?
        return # Already destroyed or not initialized
      end
      LibSDL3.clear_audio_stream(@audio_stream)
      LibSDL3.flush_audio_stream(@audio_stream)
      @paused = false
    end

    def destroy
      if @audio_stream
        LibSDL3.destroy_audio_stream(@audio_stream)
        @audio_stream = Pointer(LibSDL3::AudioStream).null
      end
      if @audio_buf
        LibSDL3.free(@audio_buf)
        @audio_buf = Pointer(UInt8).null
      end
      @@loaded_audio.delete(@file_path)
    end

    def duration_ms : UInt64
      if @audio_len == 0 || @spec.freq == 0 || @spec.channels == 0
        return 0_u64
      end

      # Calculate bits per sample from audio format
      bits = bits_per_sample(@spec.format)

      # Duration in seconds = (audio_len / (sample_rate * channels * (bits_per_sample / 8)))
      # Multiply by 1000 for milliseconds
      ((@audio_len.to_f * 1000_f32) / (@spec.freq * @spec.channels * (bits / 8.0))).to_u64
    end

    private def bits_per_sample(format : LibSDL3::AudioFormat) : UInt8
      case format & LibSDL3::AUDIO_MASK_BITSIZE
      when 0x0008_u16 then 8_u8  # U8, S8
      when 0x0010_u16 then 16_u8 # S16LE, S16BE
      when 0x0020_u16 then 32_u8 # S32LE, S32BE, F32LE, F32BE
      else raise "Unsupported audio format for bits_per_sample: #{format}"
      end
    end
  end
end
