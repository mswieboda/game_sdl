module GSDL
  module AudioManager
    @@mixer : LibSDL3Mixer::Mixer* = Pointer(LibSDL3Mixer::Mixer).null
    @@audio_assets = Hash(String, GSDL::Audio).new
    @@mutex = Mutex.new

    # Sets up the AudioManager.
    # This should be called once at the start of the application.
    def self.setup
      # Initialize SDL_mixer and create the mixer instance
      unless SDL3::Mixer.init
        raise "Failed to initialize SDL_mixer: #{SDL3.get_error}"
      end

      @@mixer = LibSDL3Mixer.create_mixer_device(LibSDL3::AUDIO_DEVICE_DEFAULT_PLAYBACK, Pointer(LibSDL3::AudioSpec).null)
      if @@mixer.null?
        raise "Failed to create SDL_mixer: #{SDL3.get_error}"
      end
    end

    private def self.mixer : LibSDL3Mixer::Mixer*
      @@mixer.null? ? raise("AudioManager not setup with a mixer!") : @@mixer
    end

    # Loads an audio file based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending GSDL::AssetManager.asset_path.
    def self.load(key : String, path_key : String, category : String? = nil) : GSDL::Audio
      @@mutex.synchronize do
        if @@audio_assets.has_key?(key)
          return @@audio_assets[key]
        end

        # Using flag?(:release) for compile-time conditional compilation.
        audio_instance = {% if flag?(:release) %}
          # In release mode, use AssetManager to load from the packfile.
          # The `with_io_stream` method ensures the underlying data stays alive.
          # with audio, the io_stream needs to stay open, hence `close_io: false`
          AssetManager.with_io_stream(path_key, close_io: false) do |io_stream|
            load_audio_from_io(key, io_stream, category)
          end
        {% else %}
          # In debug mode, load from loose files
          full_path = GSDL::AssetManager.asset_path + path_key
          audio_lib = LibSDL3Mixer.load_audio(mixer, full_path.to_unsafe, true)
          if audio_lib.null?
            raise "Failed to load audio file '#{full_path}': #{SDL3.get_error}"
          end

          track_lib = LibSDL3Mixer.create_track(mixer)
          if track_lib.null?
            LibSDL3Mixer.destroy_audio(audio_lib)
            raise "Failed to create track for '#{full_path}': #{SDL3.get_error}"
          end

          unless LibSDL3Mixer.set_track_audio(track_lib, audio_lib)
            LibSDL3Mixer.destroy_track(track_lib)
            LibSDL3Mixer.destroy_audio(audio_lib)
            raise "Failed to set audio to track for '#{full_path}': #{SDL3.get_error}"
          end

          GSDL::Audio.new(full_path, audio_lib, track_lib)
        {% end %}

        audio_instance.category = category if category
        @@audio_assets[key] = audio_instance
        audio_instance
      end
    end

    # Loads audio from raw byte data and associates it with a key
    def self.load_from_memory(key : String, io : SDL3::IOStream, category : String? = nil) : GSDL::Audio
      @@mutex.synchronize do
        if @@audio_assets.has_key?(key)
          return @@audio_assets[key]
        end

        audio_instance = load_audio_from_io(key, io, category)
        audio_instance.category = category if category
        @@audio_assets[key] = audio_instance
        audio_instance
      end
    end

    private def self.load_audio_from_io(key : String, io : SDL3::IOStream, category : String? = nil) : GSDL::Audio
      audio_lib = LibSDL3Mixer.load_audio_io(mixer, io, predecode: true, closeio: true)
      if audio_lib.null?
        raise "Failed to load audio from memory for key '#{key}': #{SDL3.get_error}"
      end

      track_lib = LibSDL3Mixer.create_track(mixer)
      if track_lib.null?
        LibSDL3Mixer.destroy_audio(audio_lib)
        raise "Failed to create track for key '#{key}': #{SDL3.get_error}"
      end

      unless LibSDL3Mixer.set_track_audio(track_lib, audio_lib)
        LibSDL3Mixer.destroy_track(track_lib)
        LibSDL3Mixer.destroy_audio(audio_lib)
        raise "Failed to set audio to track for key '#{key}': #{SDL3.get_error}"
      end

      GSDL::Audio.new(key, audio_lib, track_lib)
    end

    # Retrieves a loaded audio by its key.
    def self.get(key : String) : GSDL::Audio
      @@mutex.synchronize do
        @@audio_assets[key]? || raise "Audio with key '#{key}' not found in AudioManager. Was it loaded?"
      end
    end

    # Unloads a specific audio from memory.
    def self.unload(key : String) : Nil
      @@mutex.synchronize do
        if audio_instance = @@audio_assets.delete(key)
          audio_instance.destroy
        end
      end
    end

    # Unloads all managed audio assets from memory and destroys the mixer.
    def self.clear_all : Nil
      @@mutex.synchronize do
        @@audio_assets.each_value &.destroy
        @@audio_assets.clear

        unless @@mixer.null?
          LibSDL3Mixer.destroy_mixer(@@mixer)
          @@mixer = Pointer(LibSDL3Mixer::Mixer).null
        end
      end
    end
  end
end
