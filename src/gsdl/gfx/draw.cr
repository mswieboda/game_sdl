module GSDL
  class Draw
    @r : SDL3::Renderer

    abstract struct DrawCommand
      property z_index : Int32

      def initialize(@z_index : Int32)
      end

      def y : Num?
        nil
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
      property source_rect : SDL3::FRect?
      property dest_rect : SDL3::FRect
      property angle : Float64
      property center : SDL3::FPoint
      property flip : Int32
      property tint : Color?
      property? destroy

      def initialize(
        z_index : Int32,
        @texture : SDL3::Texture,
        @source_rect : SDL3::FRect?,
        @dest_rect : SDL3::FRect,
        @angle : Float64 = 0.0,
        @center : SDL3::FPoint = SDL3::FPoint.new,
        @flip : Int32 = 0,
        @tint : Color? = nil,
        @destroy : Bool = false
      )
        super(z_index: z_index)
      end

      def y : Num?
        @dest_rect.y
      end
    end

    struct DrawTextCommand < DrawCommand
      property text : Text

      def initialize(@text : Text)
        super(z_index: @text.z_index)
      end

      def y : Num?
        @text.y
      end
    end

    struct DrawGeometryCommand < DrawCommand
      property vertices : Array(SDL3::Vertex)
      property indices : Array(Int32)
      property texture : SDL3::Texture? = nil

      def initialize(
        z_index : Int32,
        @vertices : Array(SDL3::Vertex),
        @indices : Array(Int32),
        @texture : SDL3::Texture? = nil
      )
        super(z_index: z_index)
      end
    end

    struct DrawFRectCommand < DrawColorCommand
      property rect : SDL3::FRect
      property? outline : Bool

      def initialize(z_index : Int32, color : Color, @rect : SDL3::FRect, @outline : Bool)
        super(z_index: z_index, color: color)
      end

      def y : Num?
        @rect.y
      end
    end

    struct DrawFRectsCommand < DrawColorCommand
      property rects : Array(SDL3::FRect)
      property? outline : Bool

      def initialize(z_index : Int32, color : Color, @rects : Array(SDL3::FRect), @outline : Bool)
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
      property points : Array(SDL3::FPoint)

      def initialize(z_index : Int32, color : Color, @points : Array(SDL3::FPoint))
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

      def y : Num?
        @y1
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
      Color.new(@r.draw_color)
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
    def create_texture(surface : Surface) : Texture
      Texture.from_surface(surface)
    end

    def debug_text(*args, **options)
      @r.render_debug_text(*args, **options)
    end

    def draw
      @draw_commands.sort_by! { |c| {c.z_index, c.y.try(&.to_f32) || 0.0_f32} }

      @draw_commands.each do |command|
        color = self.color
        blend_mode = nil

        if command.is_a?(DrawColorCommand)
          self.color = command.color

          if command.color.a < 255
            blend_mode = self.blend_mode
            self.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
          end
        end

        if command.is_a?(DrawGeometryCommand)
          if command.vertices.any? { |v| v.fcolor.a < 1_f32 }
            blend_mode = self.blend_mode
            self.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
          end
        end

        case command
        when DrawTextureCommand
          _draw_texture_rotated(
            texture: command.texture,
            source_rect: command.source_rect,
            dest_rect: command.dest_rect,
            angle: command.angle,
            center: command.center,
            flip: command.flip,
            tint: command.tint,
            destroy: command.destroy?
          )
        when DrawTextCommand
          command.text._draw
        when DrawGeometryCommand
          if texture = command.texture
            @r.render_geometry(texture: texture, vertices: command.vertices, indices: command.indices)
          else
            @r.render_geometry(vertices: command.vertices, indices: command.indices)
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

        if command.is_a?(DrawColorCommand)
          self.color = color
        end

        if b_mode = blend_mode
          self.blend_mode = b_mode
        end
      end

      @draw_commands.clear

      @r.present
    end

    # geometry

    def geometry(vertices : Vertices, indices : Array(Int32), z_index : Int32 = 0, texture : Texture? = nil)
      @draw_commands << DrawGeometryCommand.new(
        z_index: z_index,
        vertices: vertices.map(&.to_sdl),
        indices: indices,
        texture: texture.try(&.to_sdl)
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

    def point(point : Point, color = Color::White, z_index = 0)
      point(x: point.x, y: point.y, color: color, z_index: z_index)
    end

    def points(points : Points, color = Color::White, z_index = 0)
      @draw_commands << DrawPointsCommand.new(
        points: points.map(&.to_sdl),
        color: color,
        z_index: z_index
      )
    end

    # draws a single `Pixel`
    def pixel(pixel : Pixel)
      point(x: pixel.x.to_f32, y: pixel.y.to_f32, color: pixel.color, z_index: pixel.z_index)
    end

    # draws multiple `Pixel` via SDL3 points,
    # takes the first pixel's `Pixel#color` and `Pixel#z_index`,
    # and internally calls `LibSDL3.render_points`
    def pixels(pixels : Pixels)
      pixel = pixels.first
      points(points: pixels.map(&.to_point), color: pixel.color, z_index: pixel.z_index)
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

    def lines(points : Points, color = Color::White, z_index = 0)
      @draw_commands << DrawLinesCommand.new(
        points: points.map(&.to_sdl),
        color: color,
        z_index: z_index
      )
    end

    # rects

    def rect_fill(rect : FRect, color = Color::White, z_index : Int32 = 0)
      @draw_commands << DrawFRectCommand.new(
        rect: rect.to_sdl,
        color: color,
        outline: false,
        z_index: z_index
      )
    end

    def rect_fill(rect : Rect, color = Color::White, z_index : Int32 = 0)
      rect_fill(rect: rect.to_frect, color: color, z_index: z_index)
    end

    def rect_fill(box : Box)
      rect_fill(rect: box.to_frect, color: box.color, z_index: box.z_index)
    end

    def rects_fill(rects : FRects, color = Color::White, z_index = 0)
      @draw_commands << DrawFRectsCommand.new(
        rects: rects.map(&.to_sdl),
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
        rect: rect.to_sdl,
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

    def rects_outline(rects : FRects, color = Color::White, z_index = 0)
      @draw_commands << DrawFRectsCommand.new(
        rects: rects.map(&.to_sdl),
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
      texture : Texture,
      x : Float32 = 0.0_f32,
      y : Float32 = 0.0_f32,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      flip : Int32 = 0,
      z_index : Int32 = 0,
      tint : Color = Color::White,
      destroy : Bool = false,
      draw_immediately : Bool = false
    )
      texture_rotated(
        texture: texture,
        x: x,
        y: y,
        source_rect: source_rect,
        dest_rect: dest_rect,
        flip: flip,
        z_index: z_index,
        tint: tint,
        destroy: destroy,
        draw_immediately: draw_immediately
      )
    end

    def texture_rotated(
      texture : Texture,
      x : Float32 = 0.0_f32,
      y : Float32 = 0.0_f32,
      source_rect : FRect? = nil,
      dest_rect : FRect? = nil,
      angle : Num = 0.0,
      center : Point = Point.new,
      flip : Int32 = 0,
      tint : Color? = nil,
      z_index : Int32 = 0,
      destroy : Bool = false,
      draw_immediately : Bool = false
    )
      actual_dest_rect = dest_rect || FRect.new(x: x, y: y, w: texture.size[0].to_f32, h: texture.size[1].to_f32)

      if draw_immediately
        _draw_texture_rotated(
          texture: texture.to_sdl,
          source_rect: source_rect.try(&.to_sdl),
          dest_rect: actual_dest_rect.to_sdl,
          angle: angle.to_f64,
          center: center.to_sdl,
          flip: flip,
          tint: tint,
          destroy: destroy,
        )
      else
        @draw_commands << DrawTextureCommand.new(
          z_index: z_index,
          texture: texture.to_sdl,
          source_rect: source_rect.try(&.to_sdl),
          dest_rect: actual_dest_rect.to_sdl,
          angle: angle.to_f64,
          center: center.to_sdl,
          flip: flip,
          tint: tint,
          destroy: destroy
        )
      end
    end

    private def _draw_texture_rotated(
      texture : SDL3::Texture,
      source_rect : SDL3::FRect?,
      dest_rect : SDL3::FRect,
      angle : Float64 = 0.0,
      center : SDL3::FPoint = SDL3::FPoint.new,
      flip : Int32 = 0,
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
          center: center,
          tint: nil,
          destroy: false
        )

        # save the old tint
        orig_tint = texture.tint
        texture.tint = t.to_sdl
      end

      if src_rect = source_rect
        @r.render_texture_rotated(
          texture: texture,
          source_rect: src_rect,
          dest_rect: dest_rect,
          angle: angle,
          center: center,
          flip: flip
        )
      else
        @r.render_texture_rotated(
          texture: texture,
          dest_rect: dest_rect,
          angle: angle,
          center: center,
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

    def target=(texture : Texture?)
      @r.set_render_target(texture.to_sdl)
    end

    def target : Texture?
      Texture.new(@r.get_render_target)
    end

    def to_sdl
      @r
    end

    def vsync=(vsync : Int32)
      @r.set_vsync(vsync)
    end
  end
end
