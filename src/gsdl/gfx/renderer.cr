module GSDL
  class Renderer
    @r : SDL3::Renderer

    delegate clear, to: @r
    delegate destroy, to: @r
    delegate draw_point, to: @r
    delegate draw_points, to: @r
    delegate draw_line, to: @r
    delegate draw_lines, to: @r
    delegate get_logical_presentation, to: @r
    delegate present, to: @r
    delegate render_debug_text, to: @r
    delegate render_texture, to: @r
    delegate render_texture_rotated, to: @r
    delegate set_logical_presentation, to: @r

    def initialize(window : SDL3::Window)
      @r = SDL3::Renderer.new(window)
    end

    def to_sdl
      @r
    end

    def color=(color : Color)
      @r.draw_color = {color.r, color.g, color.b, color.a}
    end

    def draw
      @r.present
    end

    def draw_rect_filled(rect : FRect)
      @r.fill_rect(rect)
    end

    def draw_rect_outline(rect : FRect)
      @r.draw_rect(rect)
    end

    def vsync=(vsync : Int32)
      @r.set_vsync(vsync)
    end

    def blend_mode=(mode : LibSDL3::BlendMode)
      @r.set_render_draw_blend_mode(mode)
    end

    def blend_mode : LibSDL3::BlendMode
      @r.get_render_draw_blend_mode
    end

    def target=(texture : Texture?)
      @r.set_render_target(texture)
    end

    def target : Texture?
      @r.get_render_target
    end

    def texture_from_surface(surface : SDL3::Surface)
      SDL3::Texture.from_surface(to_sdl, surface)
    end
  end
end
