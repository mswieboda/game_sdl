module GSDL
  class AudioManager
    @@instance : AudioManager? = nil

    @mixer : LibSDL3Mixer::Mixer*
    @audio_assets : Hash(String, GSDL::Audio)

    private def initialize
      # Initialize SDL_mixer and create the mixer instance
      unless SDL3::Mixer.init
        raise "Failed to initialize SDL_mixer: #{SDL3.get_error}"
      end

      @mixer = LibSDL3Mixer.create_mixer_device(LibSDL3::AUDIO_DEVICE_DEFAULT_PLAYBACK, Pointer(LibSDL3::AudioSpec).null)
      if @mixer.null?
        raise "Failed to create SDL_mixer: #{SDL3.get_error}"
      end

      @audio_assets = Hash(String, GSDL::Audio).new
    end

    # Sets up the singleton instance of AudioManager.
    # This should be called once at the start of the application.
    def self.setup
      raise "AudioManager already set up!" if @@instance
      @@instance = new
    end

    # Retrieves the singleton instance of AudioManager.
    # Raises an error if setup has not been called.
    def self.instance : AudioManager
      @@instance || raise("AudioManager has not been set up. Call GSDL::AudioManager.setup() first.")
    end

    # Loads an audio file from the given path and associates it with a key.
    # If an audio with the same key already exists, it will be returned.
    def self.load(key : String, path : String) : GSDL::Audio
      instance.load(key, path) # Delegate to the internal instance method
    end

    # Retrieves a loaded audio by its key.
    def self.get(key : String) : GSDL::Audio
      instance.get(key) # Delegate to the internal instance method
    end

    # Unloads a specific audio from memory.
    def self.unload(key : String) : Nil
      instance.unload(key) # Delegate to the internal instance method
    end

    # Unloads all managed audio assets from memory and destroys the mixer.
    def self.clear_all : Nil
      instance.clear_all # Delegate to the internal instance method
    end

    # --- Instance methods (called by class methods via the singleton instance) ---

    def load(key : String, path : String) : GSDL::Audio
      if @audio_assets.has_key?(key)
        return @audio_assets[key]
      end

      audio_lib = LibSDL3Mixer.load_audio(@mixer, path.to_unsafe, true)
      if audio_lib.null?
        raise "Failed to load audio file '#{path}': #{SDL3.get_error}"
      end

      track_lib = LibSDL3Mixer.create_track(@mixer)
      if track_lib.null?
        LibSDL3Mixer.destroy_audio(audio_lib)
        raise "Failed to create track for '#{path}': #{SDL3.get_error}"
      end

      unless LibSDL3Mixer.set_track_audio(track_lib, audio_lib)
        LibSDL3Mixer.destroy_track(track_lib)
        LibSDL3Mixer.destroy_audio(audio_lib)
        raise "Failed to set audio to track for '#{path}': #{SDL3.get_error}"
      end

      audio_instance = GSDL::Audio.new(path, audio_lib, track_lib)
      @audio_assets[key] = audio_instance
      audio_instance
    end

    def get(key : String) : GSDL::Audio
      @audio_assets.fetch(key) do
        raise "Audio with key '#{key}' not found in AudioManager. Was it loaded?"
      end
    end

    def unload(key : String) : Nil
      if audio_instance = @audio_assets.delete(key)
        audio_instance.destroy # This will destroy the underlying LibSDL3Mixer::Audio* and Track*
      end
    end

    def clear_all : Nil
      @audio_assets.each_value do |audio_instance|
        audio_instance.destroy
      end
      @audio_assets.clear

      if @mixer
        LibSDL3Mixer.destroy_mixer(@mixer)
        @mixer = Pointer(Void).null
      end
    end
  end
end