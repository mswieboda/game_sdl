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

    def ascent : Int32
      @internal.ascent
    end

    def clear_fallbacks : Void
      @internal.clear_fallbacks
    end

    def close : Void
      @internal.close
    end

    def descent : Int32
      @internal.descent
    end

    def faces : Int32
      @internal.faces
    end

    def family_name : String
      @internal.family_name
    end

    def fixed_width? : Bool
      @internal.fixed_width?
    end

    def height : Int32
      @internal.height
    end

    def kerning : Bool
      @internal.kerning
    end

    def kerning=(enabled : Bool)
      @internal.kerning = enabled
    end

    def line_skip : Int32
      @internal.line_skip
    end

    def line_skip=(line_skip : Int32)
      @internal.line_skip = line_skip
    end

    def measure(text : String, max_width : Int32) : Tuple(Int32, UInt64)
      @internal.measure(text, max_width)
    end

    def outline : Int32
      @internal.outline
    end

    def outline=(outline : Int32)
      @internal.outline = outline
    end

    def render_glyph_blended(char : UInt32, color : Color) : Surface
      Surface.new(@internal.render_glyph_blended(char, color))
    end

    def render_glyph_lcd(char : UInt32, fg_color : Color, bg_color : Color) : Surface
      Surface.new(@internal.render_glyph_lcd(char, fg_color, bg_color))
    end

    def render_glyph_shaded(char : UInt32, fg_color : Color, bg_color : Color) : Surface
      Surface.new(@internal.render_glyph_shaded(char, fg_color, bg_color))
    end

    def render_glyph_solid(char : UInt32, color : Color) : Surface
      Surface.new(@internal.render_glyph_solid(char, color))
    end

    def render_text_blended(text : String, color : Color) : Surface
      Surface.new(@internal.render_text_blended(text, color))
    end

    def render_text_blended_wrapped(text : String, color : Color, wrap_length : Int32) : Surface
      Surface.new(@internal.render_text_blended_wrapped(text, color, wrap_length))
    end

    def render_text_lcd(text : String, fg_color : Color, bg_color : Color) : Surface
      Surface.new(@internal.render_text_lcd(text, fg_color, bg_color))
    end

    def render_text_lcd_wrapped(text : String, fg_color : Color, bg_color : Color, wrap_length : Int32) : Surface
      Surface.new(@internal.render_text_lcd_wrapped(text, fg_color, bg_color, wrap_length))
    end

    def render_text_shaded(text : String, fg_color : Color, bg_color : Color) : Surface
      Surface.new(@internal.render_text_shaded(text, fg_color, bg_color))
    end

    def render_text_shaded_wrapped(text : String, fg_color : Color, bg_color : Color, wrap_length : Int32) : Surface
      Surface.new(@internal.render_text_shaded_wrapped(text, fg_color, bg_color, wrap_length))
    end

    def render_text_solid(text : String, color : Color) : Surface
      Surface.new(@internal.render_text_solid(text, color))
    end

    def render_text_solid_wrapped(text : String, color : Color, wrap_length : Int32) : Surface
      Surface.new(@internal.render_text_solid_wrapped(text, color, wrap_length))
    end

    def set_dpi(point_size : Float32, hdpi : Int32, vdpi : Int32) : Bool
      @internal.set_dpi(point_size, hdpi, vdpi)
    end

    def scalable? : Bool
      @internal.scalable?
    end

    def sdf : Bool
      @internal.sdf
    end

    def sdf=(enabled : Bool)
      @internal.sdf = enabled
    end

    def size : Float32
      @internal.size
    end

    def size_dpi(hdpi : Int32, vdpi : Int32) : Bool
      @internal.size_dpi(hdpi, vdpi)
    end

    def style_name : String
      @internal.style_name
    end

    def text_size(text : String) : Tuple(Int32, Int32)
      @internal.text_size(text)
    end

    def text_size_wrapped(text : String, wrap_width : Int32) : Tuple(Int32, Int32)
      @internal.text_size_wrapped(text, wrap_width)
    end

    def weight : Int32
      @internal.weight
    end

    def initialize(font : SDL3::TTF::Font, sdf : Bool = false)
      @internal = font
      self.sdf = sdf
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
      Font.new(@internal.copy, sdf: self.sdf)
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
