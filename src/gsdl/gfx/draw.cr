module GSDL
  alias Vertex = SDL3::Vertex

  def self.vertex(x : Int32 | Float32, y : Int32 | Float32, color : FColor) : Vertex
    SDL3::Vertex.new(x.to_f32, y.to_f32, color)
  end

  class Draw
    @r : SDL3::Renderer

    # TODO: rename this to DrawTextureCommand
    #   and add DrawTextCommand, DrawRectCommand, DrawLineCommand etc
    #   maybe parent abstract DrawCommand has z_index, color, destroy only
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

    # add more for text, geo etc
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
      color : Color = Color::White,
      destroy : Bool = false
    )
      @draw_commands << DrawCommand.new(z_index, texture, source_rect, dest_rect, flip, color, destroy)
    end

    private def set_color(color : Color)
      @r.draw_color = {color.r, color.g, color.b, color.a}
    end

    def color : Color
      @r.draw_color
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
        draw_texture_rotated(
          texture: command.texture,
          source_rect: command.source_rect,
          dest_rect: command.dest_rect,
          flip: command.flip,
          color: command.color,
          destroy: command.destroy?,
        )
      end

      @draw_commands.clear

      @r.present
    end

    # geometry

    def geometry(vertices : Array(Vertex), indices : Array(Int32))
      @r.render_geometry(vertices, indices)
    end

    def geometry(texture : Texture, vertices : Array(Vertex), indices : Array(Int32))
      @r.render_geometry(texture, vertices, indices)
    end

    # points

    def point(x : Float32, y : Float32)
      @r.draw_point(x: x, y: y)
    end

    def point(point : SDL3::FPoint)
      point(x: point.x, y: point.y)
    end

    def point(point : Point)
      point(point.x.to_f32, point.y.to_f32)
    end

    def points(points : Array(SDL3::FPoint))
      slice = Slice.new(points.to_unsafe, points.size)

      @r.draw_points(slice)
    end

    def points(points : Array(Point))
      points(points.map(&.to_fpoint))
    end

    def pixel(pixel : Pixel)
      point(pixel.x.to_f32, pixel.y.to_f32)
    end

    def pixels(pixels : Array(Point))
      points(pixels.map(&.to_fpoint))
    end

    # lines

    def line(x1 : Int32 | Float32, y1 : Int32 | Float32, x2 : Int32 | Float32, y2 : Int32 | Float32)
      @r.draw_line(x1: x1.to_f32, y1: y1.to_f32, x2: x2.to_f32, y2: y2.to_f32)
    end

    def line(line : Line)
      @r.draw_line(
        x1: line.x1.to_f32,
        y1: line.y1.to_f32,
        x2: line.x2.to_f32,
        y2: line.y2.to_f32
      )
    end

    def lines(points : Array(FPoint))
      slice = Slice.new(points.to_unsafe, points.size)

      @r.draw_lines(slice)
    end

    def lines(points : Array(Point))
      lines(points.map(&.to_fpoint))
    end

    # rects

    def filled(rect : FRect)
      @r.fill_rect(rect)
    end

    def filled(rect : Rect | Box)
      filled(rect.to_frect)
    end

    def filled(rects : Array(FRect))
      slice = Slice.new(rects.to_unsafe, rects.size)

      @r.fill_rects(slice)
    end

    def filled(rects : Array(Rect | Box))
      filled(rects.map(&.to_frect))
    end

    def outline(rect : FRect)
      @r.draw_rect(rect)
    end

    def outline(rect : Rect | Box)
      outline(rect.to_frect)
    end

    def outlines(rects : Array(FRect))
      slice = Slice.new(rects.to_unsafe, rects.size)

      @r.draw_rects(slice)
    end

    def outlines(rects : Array(Rect | Box))
      outlines(rects.map(&.to_frect))
    end

    def outline(rects : Array(FRect))
      outlines(rects)
    end

    def outline(rects : Array(Rect | Box))
      outlines(rects)
    end

    # text

    def text(text : Text)
      # TODO: add to draw commands

      # NOTE: doesn't need @r, see SDL3::TTF::Text, it's because
      #   GSDL::Text#text_sdl is created with a SDL3::TTF::TextEngine
      text._draw
    end

    # textures

    def texture(
      texture : SDL3::Texture,
      x : Float32 = 0.0_f32,
      y : Float32 = 0.0_f32,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      flip : Int32 = 0,
      z_index : Int32 = 0,
      color : Color = Color::White,
      destroy : Bool = false,
      draw_immediately : Bool = false
    )
      texture_rotated(texture, x, y, source_rect, dest_rect, flip, z_index, color, destroy, draw_immediately)
    end

    def texture_rotated(
      texture : SDL3::Texture,
      x : Float32 = 0.0_f32,
      y : Float32 = 0.0_f32,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      flip : Int32 = 0,
      z_index : Int32 = 0,
      color : Color = Color::White,
      destroy : Bool = false,
      draw_immediately : Bool = false
    )
      actual_dest_rect = dest_rect || FRect.new(x: x, y: y, w: texture.size[0].to_f32, h: texture.size[1].to_f32)

      if draw_immediately
        draw_texture_rotated(
          texture: texture,
          source_rect: source_rect,
          dest_rect: actual_dest_rect,
          flip: flip,
          color: color,
          destroy: destroy,
        )
      else
        add_draw_command(z_index, texture, source_rect, actual_dest_rect, flip, color)
      end
    end

    def draw_texture_rotated(
      texture : SDL3::Texture,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      flip : Int32 = 0,
      color : Color = Color::White,
      destroy : Bool = false
    )
      set_color(color)

      if src_rect = source_rect
        @r.render_texture_rotated(
          texture: texture,
          source_rect: src_rect,
          dest_rect: dest_rect,
          flip: flip
        )
      else
        @r.render_texture_rotated(
          texture: texture,
          dest_rect: dest_rect,
          flip: flip
        )
      end

      if destroy
        texture.destroy
      end
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
