module GSDL
  class FontManager
    DEFAULT_FONT_KEY = "default"
    DEFAULT_FONT_SIZE = 16_f32

    @@instance : FontManager? = nil

    @fonts : Hash(String, SDL3::TTF::Font)

    private def initialize
      @fonts = Hash(String, SDL3::TTF::Font).new
    end

    # Sets up the singleton instance of FontManager.
    # This should be called once at the start of the application,
    # after `SDL3::TTF.init` has been called.
    def self.setup
      raise "FontManager already set up!" if @@instance
      @@instance = new
    end

    # Retrieves the singleton instance of FontManager.
    # Raises an error if setup has not been called.
    def self.instance : FontManager
      @@instance || raise("FontManager has not been set up. Call GSDL::UI::FontManager.setup first.")
    end

    # Loads a font from the given path and associates it with a key.
    # If a font with the same key already exists, it will be returned.
    def self.load(key : String, path : String, size : Float32) : SDL3::TTF::Font
      instance.load(key, path, size)
    end

    # Loads a font from raw byte data and associates it with a key.
    # If a font with the same key and size already exists, it will be returned.
    def self.load_from_memory(key : String, io : SDL3::IOStream, size : Float32) : SDL3::TTF::Font
      instance.load_from_memory(key, io, size)
    end

    def self.load_default(path : String, size : Float32 = DEFAULT_FONT_SIZE)
      load(DEFAULT_FONT_KEY, path, size)
    end

    def self.get(key : String, size : Float32) : SDL3::TTF::Font
      instance.get("#{key}-#{size}")
    end

    # Retrieves a loaded font by its key.
    def self.get(key : String) : SDL3::TTF::Font
      instance.get(key)
    end

    def self.get_default(size : Float32 = DEFAULT_FONT_SIZE)
      get(DEFAULT_FONT_KEY, size)
    end

    # Unloads a specific font from memory.
    def self.unload(key : String) : Nil
      instance.unload(key)
    end

    # Unloads all managed fonts from memory.
    def self.clear_all : Nil
      instance.clear_all
    end

    # --- Instance methods (called by class methods via the singleton instance) ---

    def load(key : String, path : String, size : Float32) : SDL3::TTF::Font
      key = "#{key}-#{size}"
      if @fonts.has_key?(key)
        return @fonts[key]
      end
      font = SDL3::TTF::Font.open(path, size)
      @fonts[key] = font
      font
    end

    def load_from_memory(key : String, io : SDL3::IOStream, size : Float32) : SDL3::TTF::Font
      font_key = "#{key}-#{size}"
      if @fonts.has_key?(font_key)
        return @fonts[font_key]
      end

      font = SDL3::TTF::Font.open_io(io, size)
      @fonts[font_key] = font
      font
    end

    def get(key : String) : SDL3::TTF::Font
      @fonts.fetch(key) do
        raise "Font with key '#{key}' not found in FontManager. Was it loaded?"
      end
    end

    def unload(key : String) : Nil
      if font = @fonts.delete(key)
        font.close
      end
    end

    def clear_all : Nil
      @fonts.each_value do |font|
        font.close
      end
      @fonts.clear
    end
  end
end
