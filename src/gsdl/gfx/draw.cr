module GSDL
  class Draw
    @r : SDL3::Renderer

    delegate clear, to: @r
    delegate destroy, to: @r
    delegate get_logical_presentation, to: @r
    delegate set_logical_presentation, to: @r

    def initialize(window : SDL3::Window)
      @r = SDL3::Renderer.new(window)
    end

    def color=(color : Color)
      @r.draw_color = {color.r, color.g, color.b, color.a}
    end

    def blend_mode=(mode : LibSDL3::BlendMode)
      @r.set_render_draw_blend_mode(mode)
    end

    def blend_mode : LibSDL3::BlendMode
      @r.get_render_draw_blend_mode
    end

    def create_texture(surface : SDL3::Surface)
      SDL3::Texture.from_surface(to_sdl, surface)
    end

    def debug_text(*args, **options)
      @r.render_debug_text(*args, **options)
    end

    def draw
      @r.present
    end

    def line(*args, **options)
      @r.draw_line(*args, **options)
    end

    def lines(*args, **options)
      @r.draw_lines(*args, **options)
    end

    def point(*args, **options)
      @r.draw_point(*args, **options)
    end

    def points(*args, **options)
      @r.draw_points(*args, **options)
    end

    def rect_filled(*args, **options)
      @r.fill_rect(*args, **options)
    end

    def rect_outline(*args, **options)
      @r.draw_rect(*args, **options)
    end

    def texture(*args, **options)
      @r.render_texture(*args, **options)
    end

    def texture_rotated(*args, **options)
      @r.render_texture_rotated(*args, **options)
    end

    def target=(texture : Texture?)
      @r.set_render_target(texture)
    end

    def target : Texture?
      @r.get_render_target
    end

    def to_sdl
      @r
    end

    def vsync=(vsync : Int32)
      @r.set_vsync(vsync)
    end
  end
end
