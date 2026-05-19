module GSDL
  module FontManager
    DefaultFontKey = "default"
    DefaultFontSize = 16_f32

    @@fonts = Hash(String, Font).new
    @@base_fonts = Hash(String, Font).new
    @@mutex = Mutex.new

    # Sets up the FontManager.
    # Note: FontManager is now initialized automatically, but this method
    # is kept for consistency with other managers.
    def self.setup
    end

    # Loads a font based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending GSDL::AssetManager.asset_path.
    def self.load(key : String, path_key : String, size : Float32) : Font
      @@mutex.synchronize do
        f_key = full_key(key, size)
        if @@fonts.has_key?(f_key)
          return @@fonts[f_key]
        end

        # Using flag?(:release) for compile-time conditional compilation.
        font = {% if flag?(:release) %}
          # In release mode, defer to AssetManager which handles packfile loading
          # The `with_io_stream` method ensures the underlying data stays alive.
          # with fonts, the io_stream needs to stay open, hence `close_io: false`
          AssetManager.with_io_stream(path_key, close_io: false) do |io_stream|
            font_sdl = SDL3::TTF::Font.open_io(io_stream, size, close_io: true)
            Font.new(font_sdl)
          end
        {% else %}
          # In debug mode, load from loose files
          full_path = GSDL::AssetManager.asset_path + path_key
          font_sdl = SDL3::TTF::Font.open(full_path, size)
          Font.new(font_sdl)
        {% end %}

        @@fonts[f_key] = font
        @@base_fonts[key] = font unless @@base_fonts.has_key?(key)
        font
      end
    end

    # Loads a font from raw byte data and associates it with a key.
    def self.load_from_memory(key : String, io : SDL3::IOStream, size : Float32) : Font
      @@mutex.synchronize do
        f_key = full_key(key, size)
        if @@fonts.has_key?(f_key)
          return @@fonts[f_key]
        end

        font_sdl = SDL3::TTF::Font.open_io(io, size, close_io: true)
        font = Font.new(font_sdl)
        @@fonts[f_key] = font
        @@base_fonts[key] = font unless @@base_fonts.has_key?(key)
        font
      end
    end

    def self.load_default(path : String, size : Float32 = DefaultFontSize)
      load(DefaultFontKey, path, size)
    end

    def self.get(key : String, size : Float32) : Font
      @@mutex.synchronize do
        f_key = full_key(key, size)
        @@fonts[f_key]? || begin
          # If we don't have the sized font, try to copy it from a base font
          if base_font = @@base_fonts[key]?
            new_font = base_font.copy
            new_font.size = size
            @@fonts[f_key] = new_font
            new_font
          else
            raise "Font with key '#{key}' (and size #{size}) not found in FontManager. Was it loaded?"
          end
        end
      end
    end

    # Retrieves a loaded font by its key.
    def self.get(key : String) : Font
      @@mutex.synchronize do
        @@fonts[key]? || @@base_fonts[key]? || raise "Font with key '#{key}' not found in FontManager. Was it loaded?"
      end
    end

    def self.get_default(size : Float32 = DefaultFontSize)
      get(DefaultFontKey, size)
    end

    # Unloads a specific font from memory.
    def self.unload(key : String) : Nil
      @@mutex.synchronize do
        # This unloads ALL sizes for this key if it's a base key,
        # or just the specific size if it's a compound key
        if @@base_fonts.has_key?(key)
          @@base_fonts.delete(key)
          # Also delete all sized versions
          prefix = "#{key}-"
          @@fonts.reject! do |k, font|
            if k.starts_with?(prefix)
              font.close
              true
            else
              false
            end
          end
        elsif font = @@fonts.delete(key)
          # If this font was used as a base, remove it from base_fonts too
          @@base_fonts.reject! { |_, v| v == font }
          font.close
        end
      end
    end

    # Unloads all managed fonts from memory.
    def self.clear_all : Nil
      @@mutex.synchronize do
        # Close all unique fonts
        @@fonts.values.uniq.each &.close
        @@fonts.clear
        @@base_fonts.clear
      end
    end

    @[AlwaysInline]
    private def self.full_key(key : String, size : Float32) : String
      "#{key}-#{size}"
    end
  end
end
