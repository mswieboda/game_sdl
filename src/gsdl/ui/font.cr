require "./font_manager"

module GSDL
  class Font
    alias Align = SDL3::TTF::Align
    alias Style = SDL3::TTF::Style
    alias Hinting = SDL3::TTF::Hinting
    alias Direction = SDL3::TTF::Direction

    # Gets the default font.
    def self.default : Font
      FontManager.get_default
    end

    # Creates a new font with the default path and a specific size.
    def self.default(size : Float32) : Font
      FontManager.get_default(size)
    end

    # Loads and retrieves a font using the FontManager.
    # The key for the font manager will be "#{path}-#{size}".
    def self.get(key : String, size : Float32) : Font
      FontManager.get(key, size)
    end

    # TODO: for now not exposing these, so that GSDL consumers
    # use AssetManager and FontManager to load font assets
    # def self.open(file : String, ptsize : Float32)
    # def self.open_io(io_stream : IOStream, ptsize : Float32, close_io : Bool = false)

    @internal : SDL3::TTF::Font

    delegate ascent, to: @internal
    delegate clear_fallbacks, to: @internal
    delegate close, to: @internal
    delegate descent, to: @internal
    delegate faces, to: @internal
    delegate family_name, to: @internal
    delegate :"fixed_width?", to: @internal
    delegate height, to: @internal
    delegate kerning, :"kerning=", to: @internal
    delegate line_skip, :"line_skip=", to: @internal
    delegate measure, to: @internal
    delegate outline, :"outline=", to: @internal
    delegate render_glyph_blended, to: @internal
    delegate render_glyph_lcd, to: @internal
    delegate render_glyph_shaded, to: @internal
    delegate render_glyph_solid, to: @internal
    delegate render_text_blended, to: @internal
    delegate render_text_blended_wrapped, to: @internal
    delegate render_text_lcd, to: @internal
    delegate render_text_lcd_wrapped, to: @internal
    delegate render_text_shaded, to: @internal
    delegate render_text_shaded_wrapped, to: @internal
    delegate render_text_solid, to: @internal
    delegate render_text_solid_wrapped, to: @internal
    delegate set_dpi, to: @internal
    delegate :"scalable?", to: @internal
    delegate sdf, :"sdf=", to: @internal
    delegate size, :"size=", to: @internal
    delegate size_dpi, to: @internal
    delegate style_name, to: @internal
    delegate text_size, to: @internal
    delegate text_size_wrapped, to: @internal
    delegate weight, to: @internal

    def initialize(font : SDL3::TTF::Font)
      @internal = font
    end

    def add_fallback(font : Font)
      @internal.add_fallback(font.to_sdl)
    end

    def align=(align : Align)
      @internal.align = align
    end

    def align : Align
      @internal.align
    end

    def copy : Font
      Font.new(@internal.copy)
    end

    def create_text(engine : TextEngine, text : String) : Text
      Text.new(@internal.create_text(engine: engine.to_sdl, text: text))
    end

    def direction=(direction : Direction)
      @internal.direction = direction
    end

    def direction : Direction
      @internal.direction
    end

    def hinting=(hinting : Hinting)
      @internal.hinting = hinting
    end

    def hinting : Hinting
      @internal.hinting
    end

    def remove_fallback(font : Font)
      @internal.remove_fallback(font.to_sdl)
    end

    def size=(size : Num)
      @internal.size = size.to_f32
    end

    def style=(style : Style)
      @internal.style = style
    end

    def style : Style
      @internal.style
    end

    def to_sdl : SDL3::TTF::Font
      @internal
    end
  end
end
