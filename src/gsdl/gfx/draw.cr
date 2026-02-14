module GSDL
  class Draw
    @r : SDL3::Renderer

    struct DrawCommand
      property z_index : Int32
      property texture : SDL3::Texture
      property source_rect : FRect?
      property dest_rect : FRect
      property flip : Int32
      property color : Color
      property? destroy

      def initialize(
        @z_index : Int32,
        @texture : SDL3::Texture,
        @source_rect : FRect?,
        @dest_rect : FRect,
        @flip : Int32,
        @color : Color,
        @destroy : Bool = false
      )
      end
    end

    @draw_commands : Array(DrawCommand)

    delegate clear, to: @r
    delegate destroy, to: @r
    delegate get_logical_presentation, to: @r
    delegate set_logical_presentation, to: @r

    def initialize(window : SDL3::Window)
      @r = SDL3::Renderer.new(window)
      @draw_commands = [] of DrawCommand
    end

    def add_draw_command(
      z_index : Int32,
      texture : SDL3::Texture,
      source_rect : FRect?,
      dest_rect : FRect,
      flip : Int32,
      color : Color = Colors::White,
      destroy : Bool = false
    )
      @draw_commands << DrawCommand.new(z_index, texture, source_rect, dest_rect, flip, color, destroy)
    end

    private def set_color(color : Color)
      @r.draw_color = {color.r, color.g, color.b, color.a}
    end

    def color=(color : Color)
      set_color(color)
    end

    def blend_mode=(mode : LibSDL3::BlendMode)
      @r.set_render_draw_blend_mode(mode)
    end

    def blend_mode : LibSDL3::BlendMode
      @r.get_render_draw_blend_mode
    end

    # NOTE: only intended to be used within GSDL, so end-user doesn't
    #   have to deal with SDL3 lib directly
    def create_texture(surface : SDL3::Surface)
      SDL3::Texture.from_surface(to_sdl, surface)
    end

    def debug_text(*args, **options)
      @r.render_debug_text(*args, **options)
    end

    def draw
      @draw_commands.sort_by!(&.z_index)

      @draw_commands.each do |command|

        set_color(command.color)

        if source_rect = command.source_rect
          @r.render_texture_rotated(
            texture: command.texture,
            source_rect: source_rect,
            dest_rect: command.dest_rect,
            flip: command.flip
          )
        else
          @r.render_texture_rotated(
            texture: command.texture,
            dest_rect: command.dest_rect,
            flip: command.flip
          )
        end

        if command.destroy?
          command.texture.destroy
        end
      end

      @draw_commands.clear

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

    def texture(
      texture : SDL3::Texture,
      x : Float32 = 0.0_f32,
      y : Float32 = 0.0_f32,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      flip : Int32 = 0,
      z_index : Int32 = 0,
      color : Color = Colors::White,
      destroy : Bool = false
    )
      texture_rotated(texture, x, y, source_rect, dest_rect, flip, z_index, color)
    end

    def texture_rotated(
      texture : SDL3::Texture,
      x : Float32 = 0.0_f32,
      y : Float32 = 0.0_f32,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      flip : Int32 = 0,
      z_index : Int32 = 0,
      color : Color = Colors::White,
      destroy : Bool = false
    )
      actual_dest_rect = dest_rect || FRect.new(x: x, y: y, w: texture.size[0].to_f32, h: texture.size[1].to_f32)

      add_draw_command(z_index, texture, source_rect, actual_dest_rect, flip, color)
    end

    def target=(texture : SDL3::Texture?)
      @r.set_render_target(texture)
    end

    def target : SDL3::Texture?
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
