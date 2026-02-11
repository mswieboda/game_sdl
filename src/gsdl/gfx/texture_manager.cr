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

    # Loads a texture from the given path and associates it with a key.
    # If a texture with the same key already exists, it will be returned.
    def self.load(key : String, path : String) : SDL3::Texture
      instance.load(key, path) # Delegate to the internal instance method
    end

    # Loads a texture from raw byte data and associates it with a key.
    # If a texture with the same key already exists, it will be returned.
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
      texture = SDL3::Image.load_texture(@renderer, path)
      @textures[key] = texture
      texture
    end

    def load_from_memory(key : String, io : SDL3::IOStream) : SDL3::Texture
      if @textures.has_key?(key)
        return @textures[key]
      end
      texture = SDL3::Image.load_texture_io(@renderer, io, true)
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
