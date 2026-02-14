module GSDL
  class TextureManager
    @@instance : TextureManager? = nil

    @renderer : Renderer
    @textures : Hash(String, SDL3::Texture)

    private def initialize(@renderer : Renderer)
      @textures = Hash(String, SDL3::Texture).new
    end

    # Sets up the singleton instance of TextureManager with the given renderer.
    # This should be called once at the start of the application.
    def self.setup(renderer : Renderer)
      raise "TextureManager already set up!" if @@instance
      @@instance = new(renderer)
    end

    # Retrieves the singleton instance of TextureManager.
    # Raises an error if setup has not been called.
    def self.instance : TextureManager
      @@instance || raise("TextureManager has not been set up. Call GSDL::TextureManager.setup(renderer) first.")
    end

    # Loads a texture based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending GSDL::AssetManager.asset_path.
    def self.load(key : String, path_key : String) : SDL3::Texture
      # NOTE: In release builds, 'path_key' refers to the key in the asset pack.
      # In debug builds, 'path_key' refers to the relative path within @@asset_path.
      # example path_key in both cases: 'gfx/skeleton.png'
      # which loads file from 'assets/gfx/skeleton.png' in debug mode, or from
      # key 'gfx/skeleton.png' loading data from the asset.pack file
      # via the AssetManager manifest hash data

      # Using flag?(:release) for compile-time conditional compilation.
      # When compiling with `crystal build --release`, the :release flag is set.
      #
      {% if flag?(:release) %}
        # In release mode, use AssetManager to load from the packfile.
        # The `with_io_stream` method ensures the underlying data stays alive.
        AssetManager.with_io_stream(path_key) do |io_stream|
          load_from_memory(key, io_stream)
        end
      {% else %}
        # In debug mode, load from loose files
        # The `asset_path` is used to resolve the full path in debug mode
        full_path = GSDL::AssetManager.asset_path + path_key
        instance.load(key, full_path) # Delegate to the internal instance method
      {% end %}
    end

    # Loads a texture from raw byte data and associates it with a key.
    # This method is primarily intended to be called by load if in release mode
    def self.load_from_memory(key : String, io : SDL3::IOStream) : SDL3::Texture
      instance.load_from_memory(key, io)
    end

    # Retrieves a loaded texture by its key.
    # Returns nil if the texture is not found.
    def self.get(key : String) : SDL3::Texture
      instance.get(key) # Delegate to the internal instance method
    end

    # Unloads a specific texture from memory.
    def self.unload(key : String) : Nil
      instance.unload(key) # Delegate to the internal instance method
    end

    # Unloads all managed textures from memory.
    def self.clear_all : Nil
      instance.clear_all # Delegate to the internal instance method
    end

    # --- Instance methods (called by class methods via the singleton instance) ---

    def load(key : String, path : String) : SDL3::Texture
      if @textures.has_key?(key)
        return @textures[key]
      end
      texture = SDL3::Image.load_texture(@renderer.to_sdl, path)
      @textures[key] = texture
      texture
    end

    def load_from_memory(key : String, io : SDL3::IOStream) : SDL3::Texture
      if @textures.has_key?(key)
        return @textures[key]
      end
      texture = SDL3::Image.load_texture_io(@renderer.to_sdl, io, close_io: true)
      @textures[key] = texture
      texture
    end

    def get(key : String) : SDL3::Texture
      @textures.fetch(key) do
        raise "Texture with key '#{key}' not found in TextureManager. Was it loaded?"
      end
    end

    def unload(key : String) : Nil
      if texture = @textures.delete(key)
        texture.destroy
      end
    end

    def clear_all : Nil
      @textures.each_value do |texture|
        texture.destroy
      end
      @textures.clear
    end
  end
end
