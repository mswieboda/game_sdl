module GSDL
  alias PixelFormat = SDL3::PixelFormat
  alias TextureAccess = SDL3::TextureAccess

  struct Texture
    @internal : SDL3::Texture

    def self.from_surface(draw : Draw, surface : SDL3::Surface) : Texture
      texture = SDL3::Texture.from_surface(renderer: Game.draw_instance.to_sdl, surface: surface)
      Texture.new(texture: texture)
    end

    delegate blend_mode, :"blend_mode=", to: @internal
    delegate :"color_mod=", to: @internal
    delegate destroy, to: @internal
    delegate lock, to: @internal
    delegate scale_mode, :"scale_mode=", to: @internal
    delegate size, to: @internal
    delegate tint, :"tint=", to: @internal
    delegate unlock, to: @internal
    delegate update, to: @internal

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
        renderer: Game.draw_instance.to_sdl,
        format: format,
        access: access,
        w: width.to_i,
        h: height.to_i
      )
    end

    def to_unsafe
      pointerof(@internal)
    end

    def to_sdl
      @internal
    end
  end
end
