require "./font_manager"

module GSDL
  class Font
    alias Align = SDL3::TTF::Align

    # Gets the default font.
    def self.default : SDL3::TTF::Font
      FontManager.get_default
    end

    # Creates a new font with the default path and a specific size.
    def self.default(size : Float32) : SDL3::TTF::Font
      FontManager.get_default(size)
    end

    # Loads and retrieves a font using the FontManager.
    # The key for the font manager will be "#{path}-#{size}".
    def self.get(key : String, size : Float32) : SDL3::TTF::Font
      FontManager.get(key, size)
    end
  end
end
