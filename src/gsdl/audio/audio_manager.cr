module GSDL
  module AudioManager
    @@mixer : LibSDL3Mixer::Mixer* = Pointer(LibSDL3Mixer::Mixer).null
    @@audio_assets = Hash(String, GSDL::Audio).new
    @@registry = Hash(Symbol, String).new
    @@categories = Hash(Symbol, String?).new
    @@cache = Hash(Symbol, WeakRef(GSDL::Audio)).new
    @@mutex = Mutex.new
    @@tracks : Array(LibSDL3Mixer::Track*)? = nil
    @@track_owners : Array(GSDL::Audio?)? = nil
    @@sfx_group : LibSDL3Mixer::Group* = Pointer(LibSDL3Mixer::Group).null
    @@music_group : LibSDL3Mixer::Group* = Pointer(LibSDL3Mixer::Group).null

    # Sets up the AudioManager.
    # This should be called once at the start of the application.
    def self.setup
      tracks = Array(LibSDL3Mixer::Track*).new
      track_owners = Array(GSDL::Audio?).new

      # Initialize SDL_mixer and create the mixer instance
      unless SDL3::Mixer.init
        raise "Failed to initialize SDL_mixer: #{SDL3.get_error}"
      end

      @@mixer = LibSDL3Mixer.create_mixer_device(LibSDL3::AUDIO_DEVICE_DEFAULT_PLAYBACK, Pointer(LibSDL3::AudioSpec).null)
      if @@mixer.null?
        raise "Failed to create SDL3 Mixer: #{SDL3.get_error}"
      end

      @@sfx_group = LibSDL3Mixer.create_group(@@mixer)
      if @@sfx_group.null?
        raise "Failed to create SDL3 Mixer SFX group: #{SDL3.get_error}"
      end

      @@music_group = LibSDL3Mixer.create_group(@@mixer)
      if @@music_group.null?
        raise "Failed to create SDL3 Mixer Music group: #{SDL3.get_error}"
      end

      # Create Groups for SFX and Music
      @@sfx_group = LibSDL3Mixer.create_group(@@mixer)
      @@music_group = LibSDL3Mixer.create_group(@@mixer)

      # Allocate 32 simultaneous audio channels (tracks)
      32.times do |i|
        track = LibSDL3Mixer.create_track(@@mixer)
        if track.null?
          raise "Failed to create audio track: #{SDL3.get_error}"
        end
        tracks << track
        track_owners << nil

        # Reserve tracks 0-23 for SFX, 24-31 for Music
        if i < 24
          LibSDL3Mixer.set_track_group(track, @@sfx_group)
        else
          LibSDL3Mixer.set_track_group(track, @@music_group)
        end
      end

      @@tracks = tracks
      @@track_owners = track_owners
    end

    def self.tracks
      @@tracks.not_nil!
    end

    def self.track_owners
      @@track_owners.not_nil!
    end

    def self.mixer : LibSDL3Mixer::Mixer*
      @@mixer.null? ? raise("AudioManager not setup with a mixer!") : @@mixer
    end

    # Plays a sound effect on the first available channel (track from the pool)
    def self.play_sound(id : Symbol, loops : Int32 = 0) : Int32
      audio_asset = self.get(id)

      # Determine which range of tracks to search based on category
      is_music = ["music", "ambient"].includes?(audio_asset.category)
      range = is_music ? (24...32) : (0...24)

      # Find an available track in the designated range
      channel_id = -1
      range.each do |i|
        track = self.tracks[i]
        unless LibSDL3Mixer.track_playing(track) || LibSDL3Mixer.track_paused(track)
          channel_id = i
          break
        end
      end

      if channel_id == -1
        # If the preferred range is full, we could optionally overflow to the other,
        # but for now we'll stick to the reservation.
        STDERR.puts "Audio pool range (#{"Music" if is_music}#{"SFX" unless is_music}) exhausted! Could not play sound: #{id}"
        return -1
      end

      track = self.tracks[channel_id]

      # Assign the audio data to the selected track
      unless LibSDL3Mixer.set_track_audio(track, audio_asset.audio)
        STDERR.puts "Failed to set audio for track #{channel_id}: #{SDL3.get_error}"
        return -1
      end

      # Set looping if requested
      LibSDL3Mixer.set_track_loops(track, loops)

      # Ensure the track has the correct category tag
      LibSDL3Mixer.tag_track(track, audio_asset.category.to_unsafe)

      # Play the track (0_u32 means use default properties)
      if LibSDL3Mixer.play_track(track, 0_u32)
        # Hold a strong reference to the asset during playback to prevent GC
        self.track_owners[channel_id] = audio_asset
        return channel_id
      else
        STDERR.puts "Failed to play sound #{id} on channel #{channel_id}: #{SDL3.get_error}"
        return -1
      end
    end

    def self.stop_channel(channel_id : Int32)
      return if channel_id < 0 || channel_id >= self.tracks.size
      track = self.tracks[channel_id]
      LibSDL3Mixer.stop_track(track, 0)
    end

    def self.fade_out_channel(channel_id : Int32, duration_ms : Int32)
      return if channel_id < 0 || channel_id >= self.tracks.size
      track = self.tracks[channel_id]
      # Convert ms to frames for SDL3 Mixer
      fade_frames = LibSDL3Mixer.track_ms_to_frames(track, duration_ms.to_i64)
      LibSDL3Mixer.stop_track(track, fade_frames)
    end

    def self.get(id : Symbol) : GSDL::Audio
      @@mutex.synchronize do
        if weak_ref = @@cache[id]?
          if audio = weak_ref.value
            return audio
          end
        end

        # Check legacy loaded audio
        if audio = @@audio_assets[id.to_s]?
          return audio
        end

        path = @@registry[id]? || raise "Asset Registry Error: Symbol :#{id} was never registered!"
        category = @@categories[id]?
        audio = load_raw_audio(path, category)
        @@cache[id] = WeakRef.new(audio)
        audio
      end
    end

    # Housekeeping Maintenance Pass (Call during scene transitions)
    def self.prune_dead_references : Nil
      @@mutex.synchronize do
        @@cache.select! do |key, weak_ref|
          !weak_ref.value.nil?
        end

        # Clear owners for tracks that are no longer playing/paused to allow GC
        self.tracks.each_with_index do |track, i|
          unless LibSDL3Mixer.track_playing(track) || LibSDL3Mixer.track_paused(track)
            self.track_owners[i] = nil
          end
        end
      end
    end

    # Loads an audio file based on the mode (release/debug).
    def self.load(key : String, path_key : String, category : String? = nil) : GSDL::Audio
      @@mutex.synchronize do
        if @@audio_assets.has_key?(key)
          return @@audio_assets[key]
        end

        audio_instance = load_raw_audio(path_key, category)
        @@audio_assets[key] = audio_instance
        audio_instance
      end
    end

    private def self.load_raw_audio(path_key : String, category : String? = nil) : GSDL::Audio
      audio_instance = {% if flag?(:release) %}
        # In release mode, use AssetManager to load from the packfile.
        # The `with_io_stream` method ensures the underlying data stays alive.
        # with audio, the io_stream needs to stay open, hence `close_io: false`
        manifest_key = path_key.starts_with?("assets/") ? path_key.sub("assets/", "") : path_key
        AssetManager.with_io_stream(manifest_key, close_io: false) do |io_stream|
          load_audio_from_io(manifest_key, io_stream, category)
        end
      {% else %}
        # In debug mode, load from loose files
        full_path = if path_key.starts_with?("assets/") || path_key.starts_with?(GSDL::AssetManager.asset_path)
          path_key
        else
          GSDL::AssetManager.asset_path + path_key
        end

        full_path = FS.normalize_path(full_path)

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
      audio_instance
    end

    def self.register_pair(key : Symbol, val : String, category : String? = nil)
      @@mutex.synchronize do
        path = val.starts_with?("assets/sfx/") ? val : "assets/sfx/#{val}"
        @@registry[key] = path
        @@categories[key] = category
      end
    end

    def self.register_runtime(mappings : Hash(Symbol, String))
      mappings.each do |key, val|
        register_pair(key, val)
      end
    end

    def self.register_runtime(mappings : NamedTuple)
      mappings.each do |key, val|
        register_pair(key, val.to_s)
      end
    end

    macro register(mappings, category = nil)
      {% if mappings.is_a?(HashLiteral) || mappings.is_a?(NamedTupleLiteral) %}
        {% for key, val in mappings %}
          ::GSDL::AudioManager.register_pair(:{{key.id}}, {{val}}, {{category}})
        {% end %}
      {% else %}
        ::GSDL::AudioManager.register_runtime({{mappings}})
      {% end %}
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
        if @@audio_assets.has_key?(key)
          return @@audio_assets[key]
        end
      end

      raise "Audio with key '#{key}' not found in AudioManager. Was it loaded?"
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

        @@cache.each_value do |weak_ref|
          if audio = weak_ref.value
            audio.destroy
          end
        end
        @@cache.clear
        @@registry.clear
        @@categories.clear

        self.tracks.each do |track|
          LibSDL3Mixer.destroy_track(track)
        end
        self.tracks.clear
        self.track_owners.clear

        unless @@sfx_group.null?
          LibSDL3Mixer.destroy_group(@@sfx_group)
          @@sfx_group = Pointer(LibSDL3Mixer::Group).null
        end

        unless @@music_group.null?
          LibSDL3Mixer.destroy_group(@@music_group)
          @@music_group = Pointer(LibSDL3Mixer::Group).null
        end

        unless @@mixer.null?
          LibSDL3Mixer.destroy_mixer(@@mixer)
          @@mixer = Pointer(LibSDL3Mixer::Mixer).null
        end
      end
    end
  end
end
