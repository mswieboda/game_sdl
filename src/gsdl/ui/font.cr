require "./font_manager"

module GSDL
  class Font
    alias Align = SDL3::TTF::Align
    alias Style = SDL3::TTF::Style
    alias Hinting = SDL3::TTF::HintingFlags
    alias Direction = SDL3::TTF::Direction

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
    delegate kerning, :"kerning=" to: @internal
    delegate line_skip, :"line_skip=" to: @internal
    delegate outline, :"outline=" to: @internal
    delegate set_dpi, to: @internal
    delegate :"scalable?", to: @internal
    delegate sdf, :"sdf=" to: @internal
    delegate size, :"size=", to: @internal
    delegate size_dpi, to: @internal
    delegate style_name, to: @internal
    delegate text_size, to: @internal
    delegate weight, to: @internal

    def initialize(font : SDL3::TTF::Font)
      @internal = font
    end

    def add_fallback(font : Font)
      @internal.add_fallback(font.to_sdl)
    end

    def align=(align : Align)
      LibSDL3TTF.set_font_wrap_alignment(to_unsafe, align)
    end

    def align : Align
      LibSDL3TTF.get_font_wrap_alignment(to_unsafe)
    end

    def copy : Font
      Font.new(@internal.copy)
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

    def style=(style : Style)
      @internal.style = style
    end

    def style : Style
      @internal.style
    end
  end
end

# -------------------------------------
# --- SDL3::TTF::Font class methods ---
# -------------------------------------

def text_size(text : String) : Tuple{Int32, Int32}
  w = 0
  h = 0

  LibSDL3TTF.get_string_size(to_unsafe, text, text.bytesize, pointerof(w), pointerof(h))

  {w, h}
end

def text_size_wrapped(text : String, wrap_width : Int32) : Tuple{Int32, Int32}
  w = 0
  h = 0

  LibSDL3TTF.get_string_size_wrapped(to_unsafe, text, text.bytesize, wrap_width, pointerof(w), pointerof(h))

  {w, h}
end

def measure(text : String, max_width : Int32) : Tuple(Int32, UInt64)
  width = 0
  length = 0_u64

  LibSDL3TTF.measure_string(to_unsafe, text, text.bytesize, max_width, pointerof(width), pointerof(length))

  {width, length}
end

{% for type in ["solid", "blended"] %}
  def render_text_{{type.id}}(text : String, color : Color) : Surface
    ptr = LibSDL3TTF.render_text_{{type.id}}(to_unsafe, text.to_unsafe, text.bytesize, color)
    raise "Failed to render text {{type.id}}" if ptr.null?
    Surface.new(ptr)
  end

  def render_text_{{type.id}}_wrapped(text : String, color : Color, wrap_length : Int32) : Surface
    ptr = LibSDL3TTF.render_text_{{type.id}}_wrapped(to_unsafe, text.to_unsafe, text.bytesize, color, wrap_length)
    raise "Failed to render text {{type.id}} wrapped" if ptr.null?
    Surface.new(ptr)
  end

  def render_glyph_{{type.id}}(char : UInt32, color : Color) : Surface
    ptr = LibSDL3TTF.render_glyph_{{type.id}}(to_unsafe, char, color)
    raise "Failed to render glyph {{type.id}}" if ptr.null?
    Surface.new(ptr)
  end
{% end %}

{% for type in ["shaded", "lcd"] %}
  def render_text_{{type.id}}(text : String, fg_color : Color, bg_color : Color) : Surface
    ptr = LibSDL3TTF.render_text_{{type.id}}(to_unsafe, text.to_unsafe, text.bytesize, fg_color, bg_color)
    raise "Failed to render text {{type.id}}" if ptr.null?
    Surface.new(ptr)
  end

  def render_text_{{type.id}}_wrapped(text : String, fg_color : Color, bg_color : Color, wrap_length : Int32) : Surface
    ptr = LibSDL3TTF.render_text_{{type.id}}_wrapped(to_unsafe, text.to_unsafe, text.bytesize, fg_color, bg_color, wrap_length)
    raise "Failed to render text {{type.id}} wrapped" if ptr.null?
    Surface.new(ptr)
  end

  def render_glyph_{{type.id}}(char : UInt32, fg_color : Color, bg_color : Color) : Surface
    ptr = LibSDL3TTF.render_glyph_{{type.id}}(to_unsafe, char, fg_color, bg_color)
    raise "Failed to render glyph {{type.id}}" if ptr.null?
    Surface.new(ptr)
  end
{% end %}

def create_text(engine : TextEngine, text : String) : Text
  LibSDL3TTF.create_text(engine.to_unsafe, to_unsafe, text, text.bytesize)
end
