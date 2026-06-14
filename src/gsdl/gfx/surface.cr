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

    def self.create_text_engine : TextEngine
      TextEngine.create_surface_text_engine
    end

    def destroy : Void
      @internal.destroy
    end

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

    def w
      @internal.w
    end

    def h
      @internal.h
    end

    def width
      w
    end

    def height
      h
    end

    def draw_rect_fill(rect : Rect, color : Color)
      @internal.fill_rect(rect: rect.to_sdl, color: color)
    end

    def fill(color : Color)
      @internal.fill(color)
    end

    def blit(source_rect : Rect?, dest_rect : Rect?, dest_surface : Surface) : Bool
      @internal.blit(
        source_rect.try(&.to_sdl),
        dest_rect.try(&.to_sdl),
        dest_surface.to_sdl
      )
    end

    def to_sdl
      @internal
    end
  end
end
