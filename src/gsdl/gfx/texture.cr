module GSDL
  alias PixelFormat = SDL3::PixelFormat
  alias TextureAccess = SDL3::TextureAccess

  class Texture
    @internal : SDL3::Texture

    property atlas_rect : FRect? = nil
    property atlas_handle : SDL3::Texture? = nil

    def initialize(texture : SDL3::Texture)
      @internal = texture
    end

    def initialize(
      width : Num,
      height : Num,
      format : PixelFormat = PixelFormat::RGBA8888,
      access : TextureAccess = TextureAccess::Static
    )
      @internal = SDL3::Texture.create(
        renderer: Game.draw.to_sdl,
        format: format,
        access: access,
        w: width.to_i,
        h: height.to_i
      )
    end

    def self.from_surface(surface : Surface) : Texture
      texture = SDL3::Texture.from_surface(
        renderer: Game.draw.to_sdl,
        surface: surface.to_sdl
      )
      Texture.new(texture: texture)
    end

    def blend_mode : LibSDL3::BlendMode
      @internal.blend_mode
    end

    def blend_mode=(blend_mode : LibSDL3::BlendMode)
      @internal.blend_mode = blend_mode
    end

    def color_mod=(color : Color)
      @internal.color_mod = color.to_sdl
    end

    def alpha_mod=(alpha : UInt8)
      @internal.alpha_mod = alpha
    end

    def destroy : Void
      @internal.destroy
    end

    def lock(rect : LibSDL3::Rect?) : Tuple(Pointer(Void), Int32)
      @internal.lock(rect)
    end

    def scale_mode : LibSDL3::ScaleMode
      @internal.scale_mode
    end

    def scale_mode=(scale_mode : LibSDL3::ScaleMode) : Bool
      @internal.scale_mode = scale_mode
    end

    def size : Tuple(Float32, Float32)
      @internal.size
    end

    def width : Float32
      size[0]
    end

    def height : Float32
      size[1]
    end

    def tint=(color : Color)
      @internal.tint = color.to_sdl
    end

    def tint : Color
      Color.new(@internal.tint)
    end

    def unlock : Void
      @internal.unlock
    end

    def update(rect : LibSDL3::Rect?, pixels : Pointer(Void), pitch : Int32) : Bool
      @internal.update(rect, pixels, pitch)
    end

    def to_sdl
      @internal
    end
  end
end
