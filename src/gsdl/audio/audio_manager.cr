module GSDL
  class AudioManager
    @@instance : AudioManager? = nil

    @mixer : LibSDL3Mixer::Mixer*
    getter mixer
    @audio_assets : Hash(String, GSDL::Audio)
    @mutex = Mutex.new

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
      @@instance = new
    end

    # Retrieves the singleton instance of AudioManager.
    # Raises an error if setup has not been called.
    def self.instance : AudioManager
      @@instance || raise("AudioManager has not been set up. Call GSDL::AudioManager.setup() first.")
    end

    # Loads an audio file based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending GSDL::AssetManager.asset_path.
    def self.load(key : String, path_key : String, category : String? = nil) : GSDL::Audio
      # see TextureManager.load comments for more details on path_key
      # which is a key based on the path like 'sfx/race_car.wav'
      # and will either load from the asset.pack file in release mode
      # or from the 'assets/sfx/race_car.wav' file directly in debug mode

      # Using flag?(:release) for compile-time conditional compilation.
      # When compiling with `crystal build --release`, the :release flag is set.
      {% if flag?(:release) %}
        # In release mode, use AssetManager to load from the packfile.
        # The `with_io_stream` method ensures the underlying data stays alive.
        # with audio, the io_stream needs to stay open, hence `close_io: false`
        AssetManager.with_io_stream(path_key, close_io: false) do |io_stream|
          load_from_memory(key, io_stream, category)
        end
      {% else %}
        # In debug mode, load from loose files
        full_path = GSDL::AssetManager.asset_path + path_key
        instance.load(key, full_path, category) # Delegate to the internal instance method
      {% end %}
    end

    # Loads audio from raw byte data and associates it with a key
    # This method is primarily intended to be called by load if in release mode
    def self.load_from_memory(key : String, io : SDL3::IOStream, category : String? = nil) : GSDL::Audio
      instance.load_from_memory(key, io, category)
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

    def load(key : String, path : String, category : String? = nil) : GSDL::Audio
      @mutex.synchronize do
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
        audio_instance.category = category if category
        @audio_assets[key] = audio_instance
        audio_instance
      end
    end

    def load_from_memory(key : String, io : SDL3::IOStream, category : String? = nil) : GSDL::Audio
      @mutex.synchronize do
        if @audio_assets.has_key?(key)
          return @audio_assets[key]
        end

        audio_lib = LibSDL3Mixer.load_audio_io(@mixer, io, predecode: true, closeio: true)
        if audio_lib.null?
          raise "Failed to load audio from memory for key '#{key}': #{SDL3.get_error}"
        end

        track_lib = LibSDL3Mixer.create_track(@mixer)
        if track_lib.null?
          LibSDL3Mixer.destroy_audio(audio_lib)
          raise "Failed to create track for key '#{key}': #{SDL3.get_error}"
        end

        unless LibSDL3Mixer.set_track_audio(track_lib, audio_lib)
          LibSDL3Mixer.destroy_track(track_lib)
          LibSDL3Mixer.destroy_audio(audio_lib)
          raise "Failed to set audio to track for key '#{key}': #{SDL3.get_error}"
        end

        audio_instance = GSDL::Audio.new(key, audio_lib, track_lib) # Using key as path for now
        audio_instance.category = category if category
        @audio_assets[key] = audio_instance
        audio_instance
      end
    end

    def get(key : String) : GSDL::Audio
      @mutex.synchronize do
        @audio_assets.fetch(key) do
          raise "Audio with key '#{key}' not found in AudioManager. Was it loaded?"
        end
      end
    end

    def unload(key : String) : Nil
      @mutex.synchronize do
        if audio_instance = @audio_assets.delete(key)
          audio_instance.destroy # This will destroy the underlying LibSDL3Mixer::Audio* and Track*
        end
      end
    end

    def clear_all : Nil
      @mutex.synchronize do
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
end
