require "./font_manager"

module GSDL
  class Font
    DEFAULT_FONT_PATH = "assets/fonts/PressStart2P.ttf"
    DEFAULT_FONT_SIZE = 16_f32

    # Gets the default font.
    def self.default : SDL3::TTF::Font
      get(DEFAULT_FONT_PATH, DEFAULT_FONT_SIZE)
    end

    # Creates a new font with the default path and a specific size.
    def self.create(size : Float32) : SDL3::TTF::Font
      get(DEFAULT_FONT_PATH, size)
    end

    # Loads and retrieves a font using the FontManager.
    # The key for the font manager will be "#{path}-#{size}".
    def self.get(path : String, size : Float32) : SDL3::TTF::Font
      key = "#{path}-#{size}"
      FontManager.get(key)
    end
  end
end
