module GSDL
  class FontManager
    DefaultFontKey = "default"
    DefaultFontSize = 16_f32

    @@instance : FontManager? = nil

    @fonts : Hash(String, Font)
    @base_fonts : Hash(String, Font)

    private def initialize
      @fonts = Hash(String, Font).new
      @base_fonts = Hash(String, Font).new
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
      @@instance || raise("FontManager has not been set up. Call GSDL::FontManager.setup first.")
    end

    # Loads a font based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending GSDL::AssetManager.asset_path.
    def self.load(key : String, path_key : String, size : Float32) : Font
      # see TextureManager.load comments for more details on path_key
      # which is a key based on the path like 'fonts/PressStart2P.ttf'
      # and will either load from the asset.pack file in release mode
      # or from the 'assets/fonts/PressStart2P.ttf' file directly in debug mode

      # Using flag?(:release) for compile-time conditional compilation.
      # When compiling with `crystal build --release`, the :release flag is set.
      {% if flag?(:release) %}
        # In release mode, defer to AssetManager which handles packfile loading
        # The `with_io_stream` method ensures the underlying data stays alive.
        # with fonts, the io_stream needs to stay open, hence `close_io: false`
        AssetManager.with_io_stream(path_key, close_io: false) do |io_stream|
          load_from_memory(key, io_stream, size)
        end
      {% else %}
        # In debug mode, load from loose files
        full_path = GSDL::AssetManager.asset_path + path_key
        instance.load(key, full_path, size)
      {% end %}
    end

    # Loads a font from raw byte data and associates it with a key.
    # This method is primarily intended to be called by load if in release mode
    def self.load_from_memory(key : String, io : SDL3::IOStream, size : Float32) : Font
      instance.load_from_memory(key, io, size)
    end

    def self.load_default(path : String, size : Float32 = DefaultFontSize)
      load(DefaultFontKey, path, size)
    end

    def self.get(key : String, size : Float32) : Font
      instance.get(key, size)
    end

    # Retrieves a loaded font by its key.
    def self.get(key : String) : Font
      instance.get(key)
    end

    def self.get_default(size : Float32 = DefaultFontSize)
      get(DefaultFontKey, size)
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

    def load(key : String, path : String, size : Float32) : Font
      font_key = "#{key}-#{size}"
      if @fonts.has_key?(font_key)
        return @fonts[font_key]
      end
      font = Font.new(SDL3::TTF::Font.open(path, size))
      @fonts[font_key] = font
      @base_fonts[key] = font unless @base_fonts.has_key?(key)
      font
    end

    def load_from_memory(key : String, io : SDL3::IOStream, size : Float32) : Font
      font_key = "#{key}-#{size}"
      if @fonts.has_key?(font_key)
        return @fonts[font_key]
      end

      font = Font.new(SDL3::TTF::Font.open_io(io, size, close_io: true))
      @fonts[font_key] = font
      @base_fonts[key] = font unless @base_fonts.has_key?(key)
      font
    end

    def get(key : String, size : Float32) : Font
      font_key = "#{key}-#{size}"
      @fonts.fetch(font_key) do
        # If we don't have the sized font, try to copy it from a base font
        if base_font = @base_fonts[key]?
          new_font = base_font.copy
          new_font.size = size
          @fonts[font_key] = new_font
          new_font
        else
          raise "Font with key '#{key}' (and size #{size}) not found in FontManager. Was it loaded?"
        end
      end
    end

    def get(key : String) : Font
      @fonts[key]? || @base_fonts.fetch(key) do
        raise "Font with key '#{key}' not found in FontManager. Was it loaded?"
      end
    end

    def unload(key : String) : Nil
      # This unloads ALL sizes for this key if it's a base key,
      # or just the specific size if it's a compound key
      if @base_fonts.has_key?(key)
        @base_fonts.delete(key)
        # Also delete all sized versions
        prefix = "#{key}-"
        @fonts.reject! do |k, font|
          if k.starts_with?(prefix)
            font.close
            true
          else
            false
          end
        end
      elsif font = @fonts.delete(key)
        # If this font was used as a base, remove it from base_fonts too
        @base_fonts.reject! { |_, v| v == font }
        font.close
      end
    end

    def clear_all : Nil
      # Close all unique fonts
      @fonts.values.uniq.each do |font|
        font.close
      end
      @fonts.clear
      @base_fonts.clear
    end
  end
end
