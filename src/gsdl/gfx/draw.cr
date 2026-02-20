module GSDL
  alias Vertex = SDL3::Vertex

  def self.vertex(x : Int32 | Float32, y : Int32 | Float32, color : FColor) : Vertex
    Vertex.new(x.to_f32, y.to_f32, color)
  end

  class Draw
    @r : SDL3::Renderer

    abstract struct DrawCommand
      property z_index : Int32

      def initialize(@z_index : Int32)
      end
    end

    abstract struct DrawColorCommand < DrawCommand
      property color : Color

      def initialize(z_index : Int32, @color : Color)
        super(z_index: z_index)
      end
    end

    struct DrawTextureCommand < DrawCommand
      property texture : SDL3::Texture
      property source_rect : FRect?
      property dest_rect : FRect
      property flip : Int32
      property angle : Float64
      property tint : Color?
      property? destroy

      def initialize(
        z_index : Int32,
        @texture : SDL3::Texture,
        @source_rect : FRect?,
        @dest_rect : FRect,
        @flip : Int32,
        @angle : Float64 = 0.0,
        @tint : Color? = nil,
        @destroy : Bool = false
      )
        super(z_index: z_index)
      end
    end

    struct DrawTextCommand < DrawCommand
      property text : Text

      def initialize(@text : Text)
        super(z_index: @text.z_index)
      end
    end

    struct DrawGeometryCommand < DrawCommand
      property vertices : Array(Vertex)
      property indices : Array(Int32)
      property texture : SDL3::Texture? = nil

      def initialize(
        z_index : Int32,
        @vertices : Array(Vertex),
        @indices : Array(Int32),
        @texture : SDL3::Texture? = nil
      )
        super(z_index: z_index)
      end
    end

    struct DrawFRectCommand < DrawColorCommand
      property rect : FRect
      property? outline : Bool

      def initialize(z_index : Int32, color : Color, @rect : FRect, @outline : Bool)
        super(z_index: z_index, color: color)
      end
    end

    struct DrawFRectsCommand < DrawColorCommand
      property rects : Array(FRect)
      property? outline : Bool

      def initialize(z_index : Int32, color : Color, @rects : Array(FRect), @outline : Bool)
        super(z_index: z_index, color: color)
      end
    end

    struct DrawPointCommand < DrawColorCommand
      property x : Float32
      property y : Float32

      def initialize(z_index : Int32, color : Color, @x : Float32, @y : Float32)
        super(z_index: z_index, color: color)
      end
    end

    abstract struct DrawPointsCommandBase < DrawColorCommand
      property points : Array(FPoint)

      def initialize(z_index : Int32, color : Color, @points : Array(FPoint))
        super(z_index: z_index, color: color)
      end
    end

    struct DrawPointsCommand < DrawPointsCommandBase
    end

    struct DrawLinesCommand < DrawPointsCommandBase
    end

    struct DrawLineCommand < DrawColorCommand
      property x1 : Float32
      property y1 : Float32
      property x2 : Float32
      property y2 : Float32

      def initialize(z_index : Int32, color : Color, @x1, @y1, @x2, @y2)
        super(z_index: z_index, color: color)
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
        if command.is_a?(DrawColorCommand)
          self.color = command.color
        end

        case command
        when DrawTextureCommand
          _draw_texture_rotated(
            texture: command.texture,
            source_rect: command.source_rect,
            dest_rect: command.dest_rect,
            flip: command.flip,
            angle: command.angle,
            tint: command.tint,
            destroy: command.destroy?
          )
        when DrawTextCommand
          command.text._draw
        when DrawGeometryCommand
          if texture = command.texture
            @r.render_geometry(texture, command.vertices, command.indices)
          else
            @r.render_geometry(command.vertices, command.indices)
          end
        when DrawFRectCommand
          if command.outline?
            @r.draw_rect(command.rect)
          else
            @r.fill_rect(command.rect)
          end
        when DrawFRectsCommand
          slice = Slice.new(command.rects.to_unsafe, command.rects.size)
          if command.outline?
            @r.draw_rects(slice)
          else
            @r.fill_rects(slice)
          end
        when DrawPointCommand
          @r.draw_point(x: command.x, y: command.y)
        when DrawPointsCommand
          slice = Slice.new(command.points.to_unsafe, command.points.size)
          @r.draw_points(slice)
        when DrawLineCommand
          @r.draw_line(x1: command.x1, y1: command.y1, x2: command.x2, y2: command.y2)
        when DrawLinesCommand
          slice = Slice.new(command.points.to_unsafe, command.points.size)
          @r.draw_lines(slice)
        end
      end

      @draw_commands.clear

      @r.present
    end

    # geometry

    def geometry(vertices : Array(Vertex), indices : Array(Int32), z_index : Int32 = 0, texture : SDL3::Texture? = nil)
      @draw_commands << DrawGeometryCommand.new(
        z_index: z_index,
        vertices: vertices,
        indices: indices,
        texture: texture
      )
    end

    # points

    def point(x : Num, y : Num, color = Color::White, z_index = 0)
      @draw_commands << DrawPointCommand.new(
        z_index: z_index,
        color: color,
        x: x.to_f32,
        y: y.to_f32
      )
    end

    def point(point : FPoint, color = Color::White, z_index = 0)
      point(x: point.x, y: point.y, color: color, z_index: z_index)
    end

    def points(points : Array(FPoint), color = Color::White, z_index = 0)
      @draw_commands << DrawPointsCommand.new(
        points: points,
        color: color,
        z_index: z_index
      )
    end

    def pixel(pixel : Pixel)
      point(x: pixel.x.to_f32, y: pixel.y.to_f32, color: pixel.color, z_index: pixel.z_index)
    end

    def pixels(pixels : Array(Pixel))
      pixel = pixels.first
      points(points: pixels.map(&.to_fpoint), color: pixel.color, z_index: pixel.z_index)
    end

    # lines

    def line(x1 : Num, y1 : Num, x2 : Num, y2 : Num, color = Color::White, z_index = 0)
      @draw_commands << DrawLineCommand.new(
        z_index: z_index,
        color: color,
        x1: x1.to_f32,
        y1: y1.to_f32,
        x2: x2.to_f32,
        y2: y2.to_f32
      )
    end

    def line(line : Line)
      line(
        x1: line.x1.to_f32,
        y1: line.y1.to_f32,
        x2: line.x2.to_f32,
        y2: line.y2.to_f32,
        color: line.color,
        z_index: line.z_index
      )
    end

    def lines(points : Array(FPoint), color = Color::White, z_index = 0)
      @draw_commands << DrawLinesCommand.new(
        points: points,
        color: color,
        z_index: z_index
      )
    end

    # rects

    def rect_fill(rect : FRect, color = Color::White, z_index : Int32 = 0)
      @draw_commands << DrawFRectCommand.new(z_index: z_index, color: color, rect: rect, outline: false)
    end

    def rect_fill(rect : Rect, color = Color::White, z_index : Int32 = 0)
      rect_fill(rect: rect.to_frect, color: color, z_index: z_index)
    end

    def rect_fill(box : Box)
      rect_fill(rect: box.to_frect, color: box.color, z_index: box.z_index)
    end

    def rects_fill(rects : Array(FRect), color = Color::White, z_index = 0)
      @draw_commands << DrawFRectsCommand.new(
        rects: rects,
        color: color,
        z_index: z_index,
        outline: false
      )
    end

    def rects_fill(rects : Array(Rect), color = Color::White, z_index = 0)
      rects_fill(rects: rects.map(&.to_frect), color: color, z_index: z_index)
    end

    def rects_fill(boxes : Array(Box))
      box = boxes.first.color
      rects_fill(rects: boxes.map(&.to_frect), color: box.color, z_index: box.z_index)
    end

    def rect_outline(rect : FRect, color = Color::White, z_index : Int32 = 0)
      @draw_commands << DrawFRectCommand.new(
        rect: rect,
        color: color,
        z_index: z_index,
        outline: true
      )
    end

    def rect_outline(rect : Rect, color = Color::White, z_index : Int32 = 0)
      rect_outline(rect: rect.to_frect, color: color, z_index: z_index)
    end

    def rect_outline(box : Box)
      rect_outline(rect: box.to_frect, color: box.color, z_index: box.z_index)
    end

    def rects_outline(rects : Array(FRect), color = Color::White, z_index = 0)
      @draw_commands << DrawFRectsCommand.new(
        rects: rects,
        color: color,
        z_index: z_index,
        outline: true
      )
    end

    def rects_outline(rects : Array(Rect), color = Color::White, z_index = 0)
      rects_outline(rects: rects.map(&.to_frect), color: color, z_index: z_index)
    end

    def rects_outline(boxes : Array(Box))
      box = boxes.first.color
      rects_outline(rects: boxes.map(&.to_frect), color: box.color, z_index: box.z_index)
    end

    # text

    def text(text : Text)
      @draw_commands << DrawTextCommand.new(text)
    end

    # textures

    def texture(
      texture : SDL3::Texture,
      x : Float32 = 0.0_f32,
      y : Float32 = 0.0_f32,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      flip : Int32 = 0,
      angle : Num = 0.0,
      z_index : Int32 = 0,
      color : Color = Color::White,
      destroy : Bool = false,
      draw_immediately : Bool = false
    )
      texture_rotated(texture, x, y, source_rect, dest_rect, flip, angle, z_index, color, destroy, draw_immediately)
    end

    def texture_rotated(
      texture : SDL3::Texture,
      x : Float32 = 0.0_f32,
      y : Float32 = 0.0_f32,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      flip : Int32 = 0,
      angle : Num = 0.0,
      z_index : Int32 = 0,
      tint : Color? = nil,
      destroy : Bool = false,
      draw_immediately : Bool = false
    )
      actual_dest_rect = dest_rect || FRect.new(x: x, y: y, w: texture.size[0].to_f32, h: texture.size[1].to_f32)

      if draw_immediately
        _draw_texture_rotated(
          texture: texture,
          source_rect: source_rect,
          dest_rect: actual_dest_rect,
          flip: flip,
          angle: angle.to_f64,
          tint: tint,
          destroy: destroy,
        )
      else
        @draw_commands << DrawTextureCommand.new(
          z_index: z_index,
          texture: texture,
          source_rect: source_rect,
          dest_rect: actual_dest_rect,
          flip: flip,
          angle: angle.to_f64,
          tint: tint,
          destroy: destroy
        )
      end
    end

    private def _draw_texture_rotated(
      texture : SDL3::Texture,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      flip : Int32 = 0,
      angle : Float64 = 0.0,
      tint : Color? = nil,
      destroy : Bool = false
    )
      orig_tint = nil

      # set tint
      if t = tint
        # draw the original texture, so we have a tint overlay, if alpha != 255
        _draw_texture_rotated(
          texture: texture,
          source_rect: source_rect,
          dest_rect: dest_rect,
          flip: flip,
          angle: angle,
          tint: nil,
          destroy: false
        )

        # save the old tint
        orig_tint = texture.tint
        texture.tint = t
      end

      if src_rect = source_rect
        @r.render_texture_rotated(
          texture: texture,
          source_rect: src_rect,
          dest_rect: dest_rect,
          angle: angle,
          flip: flip
        )
      else
        @r.render_texture_rotated(
          texture: texture,
          dest_rect: dest_rect,
          angle: angle,
          flip: flip
        )
      end

      # put tint back to what it was
      if tint = orig_tint
        texture.tint = tint
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
