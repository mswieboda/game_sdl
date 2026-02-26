module GSDL
  class Surface
    @internal : SDL3::Surface

    # TODO: other helps maybe to include,
    # but GSDL consumers should use AssetManager / TextureManger
    # to load assets instead
    # def self.load_bmp(file : String)
    # def self.load_io(io_stream : IOStream, close_io : Bool = false)
    # def self.load_bmp_io(io_stream : IOStream, close_io : Bool = false)
    # def self.load_png_io(io_stream : IOStream, close_io : Bool = false)
    def self.create_text_engine : SDL3::TTF::TextEngine
      SDL3::TTF::TextEngine.create(Type::Surface)
    end

    delegate destroy, to: @internal

    def initialize(surface : SDL3::Surface)
      @internal = surface
    end

    def initialize(width : Int32 = 0, height : Int32 = 0, format : LibSDL3::PixelFormat = LibSDL3::PixelFormat::RGBA8888)
      @internal = SDL3::Surface.new(
        width: width,
        height: height,
        format: format
      )
    end

    def draw_rect_fill(rect : Rect, color : Color)
      @internal.fill_rect(rect: rect.to_sdl, color: color.to_sdl)
    end

    def draw_text(text : Text, x : Num, y : Num) : Bool
      @internal.draw_text(text: text.to_sdl, x: x.to_f32, y: y.to_f32)
    end

    def fill(color : Color)
      @internal.fill(color.to_sdl)
    end

    def to_sdl
      @internal
    end
  end
end
