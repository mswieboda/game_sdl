module GSDL
  class Draw
    @r : SDL3::Renderer

    # Switch to classes for heap allocation and better release-mode stability
    abstract class DrawCommand
      property z_index : Int32
      property scale_x : Float32
      property scale_y : Float32
      property clip_rect : SDL3::Rect?

      def initialize(@z_index : Int32, @scale_x : Float32, @scale_y : Float32, @clip_rect : SDL3::Rect? = nil)
      end

      def y : Num?
        nil
      end

      def on_screen? : Bool
        true
      end
    end

    abstract class DrawColorCommand < DrawCommand
      property color : Color

      def initialize(z_index : Int32, @color : Color, scale_x : Float32, scale_y : Float32, clip_rect : SDL3::Rect? = nil)
        super(z_index: z_index, scale_x: scale_x, scale_y: scale_y, clip_rect: clip_rect)
      end
    end

    class DrawTextureCommand < DrawCommand
      property texture : SDL3::Texture
      property source_rect : SDL3::FRect?
      property dest_rect : SDL3::FRect
      property angle : Float64
      property center : SDL3::FPoint
      property flip : Int32
      property tint_r : UInt8 = 255_u8
      property tint_g : UInt8 = 255_u8
      property tint_b : UInt8 = 255_u8
      property tint_a : UInt8 = 255_u8
      property? has_tint : Bool = false
      property? destroy
      property sort_y : Float32?

      def initialize(
        z_index : Int32,
        @texture : SDL3::Texture,
        @source_rect : SDL3::FRect?,
        @dest_rect : SDL3::FRect,
        scale_x : Float32,
        scale_y : Float32,
        @angle : Float64 = 0.0,
        @center : SDL3::FPoint = SDL3::FPoint.new,
        @flip : Int32 = 0,
        tint : Color? = nil,
        @destroy : Bool = false,
        clip_rect : SDL3::Rect? = nil,
        @sort_y : Float32? = nil
      )
        super(z_index: z_index, scale_x: scale_x, scale_y: scale_y, clip_rect: clip_rect)
        if t = tint
          @tint_r, @tint_g, @tint_b, @tint_a = t.r, t.g, t.b, t.a
          @has_tint = true
        end
      end

      def y : Num?
        @sort_y || @dest_rect.y
      end

      def tint : Color
        nil unless has_tint?

        Color.new(r: tint_r, g: tint_g, b: tint_b, a: tint_a)
      end

      def on_screen? : Bool
        # Get actual screen dimensions for culling
        screen_w = GSDL::Game.width.to_f32
        screen_h = GSDL::Game.height.to_f32

        # Basic bounding box check with circumscribed circle to account for arbitrary rotation
        cx = (@dest_rect.x + @dest_rect.w / 2_f32) * scale_x.abs
        cy = (@dest_rect.y + @dest_rect.h / 2_f32) * scale_y.abs

        radius = Math.max(@dest_rect.w, @dest_rect.h) * 0.75_f32
        radius *= Math.max(scale_x.abs, scale_y.abs)

        cx + radius >= 0_f32 && cx - radius <= screen_w && cy + radius >= 0_f32 && cy - radius <= screen_h
      end
    end

    class DrawTextCommand < DrawCommand
      property text : Text
      property screen_x : Float32
      property screen_y : Float32

      def initialize(@text : Text, scale_x : Float32, scale_y : Float32, clip_rect : SDL3::Rect? = nil)
        super(z_index: @text.z_index, scale_x: scale_x, scale_y: scale_y, clip_rect: clip_rect)
        @screen_x = @text.draw_x.to_f32
        @screen_y = @text.draw_y.to_f32
      end

      def y : Num?
        @text.y
      end

      def on_screen? : Bool
        screen_w = GSDL::Game.width.to_f32
        screen_h = GSDL::Game.height.to_f32

        sx = @screen_x * scale_x.abs
        sy = @screen_y * scale_y.abs
        r_w = @text.width.to_f32 * scale_x.abs
        r_h = @text.height.to_f32 * scale_y.abs

        sx + r_w >= 0_f32 && sx <= screen_w && sy + r_h >= 0_f32 && sy <= screen_h
      end
    end

    class DrawGeometryCommand < DrawCommand
      property vertices : Array(SDL3::Vertex)
      property indices : Array(Int32)
      property texture : SDL3::Texture? = nil

      def initialize(
        z_index : Int32,
        @vertices : Array(SDL3::Vertex),
        @indices : Array(Int32),
        scale_x : Float32,
        scale_y : Float32,
        @texture : SDL3::Texture? = nil,
        clip_rect : SDL3::Rect? = nil
      )
        super(z_index: z_index, scale_x: scale_x, scale_y: scale_y, clip_rect: clip_rect)
      end
    end

    class DrawFRectCommand < DrawColorCommand
      property rect : SDL3::FRect
      property? outline : Bool

      def initialize(z_index : Int32, color : Color, @rect : SDL3::FRect, @outline : Bool, scale_x : Float32, scale_y : Float32, clip_rect : SDL3::Rect? = nil)
        super(z_index: z_index, color: color, scale_x: scale_x, scale_y: scale_y, clip_rect: clip_rect)
      end

      def y : Num?
        @rect.y
      end

      def on_screen? : Bool
        screen_w = GSDL::Game.width.to_f32
        screen_h = GSDL::Game.height.to_f32

        r_x = @rect.x * scale_x.abs
        r_y = @rect.y * scale_y.abs
        r_w = @rect.w * scale_x.abs
        r_h = @rect.h * scale_y.abs

        r_x + r_w >= 0_f32 && r_x <= screen_w && r_y + r_h >= 0_f32 && r_y <= screen_h
      end
    end

    class DrawFRectsCommand < DrawColorCommand
      property rects : Array(SDL3::FRect)
      property? outline : Bool

      def initialize(z_index : Int32, color : Color, @rects : Array(SDL3::FRect), @outline : Bool, scale_x : Float32, scale_y : Float32, clip_rect : SDL3::Rect? = nil)
        super(z_index: z_index, color: color, scale_x: scale_x, scale_y: scale_y, clip_rect: clip_rect)
      end
    end

    class DrawPointCommand < DrawColorCommand
      property x : Float32
      property y : Float32

      def initialize(z_index : Int32, color : Color, @x : Float32, @y : Float32, scale_x : Float32, scale_y : Float32, clip_rect : SDL3::Rect? = nil)
        super(z_index: z_index, color: color, scale_x: scale_x, scale_y: scale_y, clip_rect: clip_rect)
      end

      def on_screen? : Bool
        screen_w = GSDL::Game.width.to_f32
        screen_h = GSDL::Game.height.to_f32
        px = @x * scale_x.abs
        py = @y * scale_y.abs
        px >= 0_f32 && px <= screen_w && py >= 0_f32 && py <= screen_h
      end
    end

    abstract class DrawPointsCommandBase < DrawColorCommand
      property points : Array(SDL3::FPoint)

      def initialize(z_index : Int32, color : Color, @points : Array(SDL3::FPoint), scale_x : Float32, scale_y : Float32, clip_rect : SDL3::Rect? = nil)
        super(z_index: z_index, color: color, scale_x: scale_x, scale_y: scale_y, clip_rect: clip_rect)
      end
    end

    class DrawPointsCommand < DrawPointsCommandBase
    end

    class DrawLinesCommand < DrawPointsCommandBase
    end

    class DrawLineCommand < DrawColorCommand
      property x1 : Float32
      property y1 : Float32
      property x2 : Float32
      property y2 : Float32

      def initialize(z_index : Int32, color : Color, @x1, @y1, @x2, @y2, scale_x : Float32, scale_y : Float32, clip_rect : SDL3::Rect? = nil)
        super(z_index: z_index, color: color, scale_x: scale_x, scale_y: scale_y, clip_rect: clip_rect)
      end

      def y : Num?
        @y1
      end
    end

    alias Command = DrawTextureCommand | DrawTextCommand | DrawFRectCommand | DrawPointCommand | DrawLineCommand | DrawGeometryCommand | DrawFRectsCommand | DrawPointsCommand | DrawLinesCommand

    class Layer
      getter commands = [] of Command
      property? dirty = false

      def push(cmd : Command)
        @commands << cmd
        @dirty = true
      end

      def clear
        @commands.clear
        @dirty = false
      end

      def sort!
        return unless @dirty
        @commands.sort! do |a, b|
          ay = a.y.try(&.to_f32) || 0.0_f32
          by = b.y.try(&.to_f32) || 0.0_f32
          ay <=> by
        end
        @dirty = false
      end
    end

    @layers : Hash(Int32, Layer)
    @sorted_z_indices : Array(Int32)
    @text_engine : TextEngine?
    @current_command_count : Int32 = 0
    @last_command_count : Int32 = 0

    def command_count : Int32
      @current_command_count > 0 ? @current_command_count : @last_command_count
    end

    property culling_enabled : Bool = true

    def text_engine : TextEngine
      @text_engine ||= TextEngine.new(@r.create_text_engine)
    end

    def clear : Bool
      @r.clear
    end

    def destroy : Void
      @text_engine.try(&.destroy)
      @r.destroy
    end

    def logical_presentation
      @r.logical_presentation
    end

    def logical_presentation=(data : Tuple(Int32, Int32, LibSDL3::RendererLogicalPresentation))
      @r.logical_presentation = data
    end

    property current_scale_x : Float32 = 1_f32
    property current_scale_y : Float32 = 1_f32
    property current_clip_rect : SDL3::Rect? = nil

    def scale=(val : Float32)
      @current_scale_x = val
      @current_scale_y = val
    end

    def scale=(val : Tuple(Float32, Float32))
      @current_scale_x = val[0]
      @current_scale_y = val[1]
    end

    def scale
      {@current_scale_x, @current_scale_y}
    end

    def clip_rect=(rect : SDL3::Rect?)
      @current_clip_rect = rect
    end

    def clip_rect=(rect : GSDL::Rect?)
      @current_clip_rect = rect.try(&.to_sdl)
    end

    def clip_rect
      @current_clip_rect
    end

    private def push_cmd(cmd : Command)
      c = cmd

      # Still cull if enabled, but use local variables to be safe
      if @culling_enabled && !c.on_screen?
        return
      end

      layer = @layers[c.z_index] ||= begin
        @sorted_z_indices << c.z_index
        @sorted_z_indices.sort!
        Layer.new
      end
      layer.push(c)
      @current_command_count += 1
    end

    def initialize(window : SDL3::Window)
      @r = SDL3::Renderer.new(window)
      @layers = Hash(Int32, Layer).new
      @sorted_z_indices = [] of Int32
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
      @r.blend_mode = mode
    end

    def blend_mode : LibSDL3::BlendMode
      @r.blend_mode
    end

    def create_texture(surface : Surface) : Texture
      Texture.from_surface(surface)
    end

    def draw
      @last_command_count = @current_command_count
      @current_command_count = 0

      active_scale_x = 1_f32
      active_scale_y = 1_f32
      active_clip_rect : SDL3::Rect? = nil
      active_color : Color? = nil
      active_blend_mode : LibSDL3::BlendMode? = nil

      @r.scale = {1_f32, 1_f32}
      @r.clip_rect = nil
      @r.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND

      @sorted_z_indices.each do |z|
        layer = @layers[z]
        next if layer.commands.empty?

        layer.sort!
        commands = layer.commands

        cursor = 0
        while cursor < commands.size
          command = commands[cursor]

          # Sync Renderer Scale
          if command.scale_x != active_scale_x || command.scale_y != active_scale_y
            active_scale_x = command.scale_x
            active_scale_y = command.scale_y
            @r.scale = {active_scale_x, active_scale_y}
          end

          # Sync Clip Rect
          if command.clip_rect != active_clip_rect
            active_clip_rect = command.clip_rect
            @r.clip_rect = active_clip_rect
          end

          # Handle Commands requiring explicit color/blend mode
          if command.is_a?(DrawColorCommand)
            if command.color != active_color
              active_color = command.color
              set_color(active_color.as(Color))
            end

            # DEFENSIVE: Always force BLEND mode for everything for now
            needed_blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
            if needed_blend_mode != active_blend_mode
              active_blend_mode = needed_blend_mode
              @r.blend_mode = active_blend_mode
            end
          end

          case command
          when DrawFRectCommand
            command.outline? ? @r.draw_rect(command.rect) : @r.fill_rect(command.rect)

          when DrawTextureCommand
            # Reset tracking to ensure every texture draw sets its own state
            active_color = nil
            active_blend_mode = nil

            # FORCE BLEND mode for both renderer and texture for EVERY DRAW
            @r.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
            command.texture.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND

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
            active_color = nil
            active_blend_mode = nil
            command.text._draw(command.screen_x, command.screen_y)

          when DrawGeometryCommand
            active_color = nil
            active_blend_mode = nil

            @r.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
            if texture = command.texture
              texture.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
              texture.tint = SDL3::Color.new(r: 255, g: 255, b: 255, a: 255)
              @r.render_geometry(texture: texture, vertices: command.vertices, indices: command.indices)
            else
              @r.render_geometry(vertices: command.vertices, indices: command.indices)
            end

          when DrawFRectsCommand
            slice = Slice.new(command.rects.to_unsafe, command.rects.size)
            command.outline? ? @r.draw_rects(slice) : @r.fill_rects(slice)

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

          cursor += 1
        end

        layer.clear
      end

      @r.scale = {1_f32, 1_f32}
      @r.present
    end

    private def can_batch_rect?(next_cmd : DrawCommand, current_cmd : DrawFRectCommand, active_color : Color?, scale_x : Float32, scale_y : Float32, clip_rect : SDL3::Rect?) : Bool
      false
    end

    private def can_batch_texture?(next_cmd : Command, current_cmd : Command, scale_x : Float32, scale_y : Float32, clip_rect : SDL3::Rect?) : Bool
      false
    end

    private def _render_texture_rotated(
      texture : SDL3::Texture,
      source_rect : SDL3::FRect?,
      dest_rect : SDL3::FRect,
      angle : Float64 = 0.0,
      center : SDL3::FPoint = SDL3::FPoint.new,
      flip : Int32 = 0
    )
      @r.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
      texture.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND

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
      orig_tint = texture.tint
      orig_blend_mode = texture.blend_mode
      orig_renderer_blend_mode = @r.blend_mode

      # TODO: maybe this should only happen for tints? but keep as-is for now
      texture.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
      @r.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND

      if (t = tint) && !t.white?
        # Pass 1: Base texture (Full original alpha)
        texture.tint = Color::White.to_sdl
        _render_texture_rotated(texture, source_rect, dest_rect, angle, center, flip)

        # Pass 2: Tint overlay (Target color and alpha)
        texture.tint = SDL3::Color.new(r: t.r, g: t.g, b: t.b, a: t.a)
        _render_texture_rotated(texture, source_rect, dest_rect, angle, center, flip)
      else
        # Single pass: No tint or Alpha-only tint
        if tint_val = tint
          texture.tint = SDL3::Color.new(r: 255, g: 255, b: 255, a: tint_val.a)
        else
          texture.tint = Color::White.to_sdl
        end

        _render_texture_rotated(texture, source_rect, dest_rect, angle, center, flip)
      end

      texture.tint = orig_tint
      texture.blend_mode = orig_blend_mode
      @r.blend_mode = orig_renderer_blend_mode

      if destroy
        texture.destroy
      end
    end

    # geometry

    def geometry(vertices : Vertices, indices : Array(Int32), z_index : Int32 = 0, texture : Texture? = nil)
      push_cmd(DrawGeometryCommand.new(
        z_index: z_index,
        vertices: vertices.map(&.to_sdl),
        indices: indices,
        texture: texture.try(&.to_sdl),
        scale_x: @current_scale_x,
        scale_y: @current_scale_y,
        clip_rect: @current_clip_rect
      ))
    end

    # points

    def point(x : Num, y : Num, color = Color::White, z_index = 0)
      push_cmd(DrawPointCommand.new(
        z_index: z_index,
        color: color,
        x: x.to_f32,
        y: y.to_f32,
        scale_x: @current_scale_x,
        scale_y: @current_scale_y,
        clip_rect: @current_clip_rect
      ))
    end

    def point(point : Point, color = Color::White, z_index = 0)
      point(x: point.x, y: point.y, color: color, z_index: z_index)
    end

    def points(points : Points, color = Color::White, z_index = 0)
      push_cmd(DrawPointsCommand.new(
        points: points.map(&.to_sdl),
        color: color,
        z_index: z_index,
        scale_x: @current_scale_x,
        scale_y: @current_scale_y,
        clip_rect: @current_clip_rect
      ))
    end

    def pixel(pixel : Pixel)
      point(x: pixel.x.to_f32, y: pixel.y.to_f32, color: pixel.color, z_index: pixel.z_index)
    end

    def pixels(pixels : Pixels)
      pixel = pixels.first
      points(points: pixels.map(&.to_point), color: pixel.color, z_index: pixel.z_index)
    end

    # lines

    def line(x1 : Num, y1 : Num, x2 : Num, y2 : Num, color = Color::White, z_index = 0)
      push_cmd(DrawLineCommand.new(
        z_index: z_index,
        color: color,
        x1: x1.to_f32,
        y1: y1.to_f32,
        x2: x2.to_f32,
        y2: y2.to_f32,
        scale_x: @current_scale_x,
        scale_y: @current_scale_y,
        clip_rect: @current_clip_rect
      ))
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
      push_cmd(DrawLinesCommand.new(
        points: points.map(&.to_sdl),
        color: color,
        z_index: z_index,
        scale_x: @current_scale_x,
        scale_y: @current_scale_y,
        clip_rect: @current_clip_rect
      ))
    end

    # circles

    def circle_fill(x : Num, y : Num, radius : Num, color = Color::White, z_index = 0)
      Circle.new(x: x, y: y, radius: radius, color: color, z_index: z_index, draw_mode: Shape::DrawMode::Fill).draw(self)
    end

    def circle_fill(circle : Circle)
      circle_fill(x: circle.x, y: circle.y, radius: circle.radius, color: circle.color, z_index: circle.z_index)
    end

    def circle_outline(x : Num, y : Num, radius : Num, color = Color::White, z_index = 0)
      Circle.new(x: x, y: y, radius: radius, color: color, z_index: z_index, draw_mode: Shape::DrawMode::Outline).draw(self)
    end

    def circle_outline(circle : Circle)
      circle_outline(x: circle.x, y: circle.y, radius: circle.radius, color: circle.color, z_index: circle.z_index)
    end

    # rects

    def rect_fill(rect : FRect, color = Color::White, z_index : Int32 = 0)
      push_cmd(DrawFRectCommand.new(
        rect: rect.to_sdl,
        color: color,
        outline: false,
        z_index: z_index,
        scale_x: @current_scale_x,
        scale_y: @current_scale_y,
        clip_rect: @current_clip_rect
      ))
    end

    def rect_fill(rect : Rect, color = Color::White, z_index : Int32 = 0)
      rect_fill(rect: rect.to_frect, color: color, z_index: z_index)
    end

    def rect_fill(box : Box)
      rect_fill(rect: box.to_frect, color: box.color, z_index: box.z_index)
    end

    def rects_fill(rects : FRects, color = Color::White, z_index = 0)
      push_cmd(DrawFRectsCommand.new(
        rects: rects.map(&.to_sdl),
        color: color,
        z_index: z_index,
        outline: false,
        scale_x: @current_scale_x,
        scale_y: @current_scale_y,
        clip_rect: @current_clip_rect
      ))
    end

    def rects_fill(rects : Array(Rect), color = Color::White, z_index = 0)
      rects_fill(rects: rects.map(&.to_frect), color: color, z_index: z_index)
    end

    def rects_fill(boxes : Array(Box))
      box = boxes.first.color
      rects_fill(rects: boxes.map(&.to_frect), color: box.color, z_index: box.z_index)
    end

    def rect_outline(rect : FRect, color = Color::White, z_index : Int32 = 0)
      push_cmd(DrawFRectCommand.new(
        rect: rect.to_sdl,
        color: color,
        z_index: z_index,
        outline: true,
        scale_x: @current_scale_x,
        scale_y: @current_scale_y,
        clip_rect: @current_clip_rect
      ))
    end

    def rect_outline(rect : Rect, color = Color::White, z_index : Int32 = 0)
      rect_outline(rect: rect.to_frect, color: color, z_index: z_index)
    end

    def rect_outline(box : Box)
      rect_outline(rect: box.to_frect, color: box.color, z_index: box.z_index)
    end

    def rects_outline(rects : FRects, color = Color::White, z_index = 0)
      push_cmd(DrawFRectsCommand.new(
        rects: rects.map(&.to_sdl),
        color: color,
        z_index: z_index,
        outline: true,
        scale_x: @current_scale_x,
        scale_y: @current_scale_y,
        clip_rect: @current_clip_rect
      ))
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
      push_cmd(DrawTextCommand.new(text, @current_scale_x, @current_scale_y, @current_clip_rect))
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
      draw_immediately : Bool = false,
      sort_y : Float32? = nil
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
        draw_immediately: draw_immediately,
        sort_y: sort_y
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
      draw_immediately : Bool = false,
      sort_y : Float32? = nil
    )
      actual_dest_rect = dest_rect || FRect.new(x: x, y: y, w: texture.size[0].to_f32, h: texture.size[1].to_f32)

      if draw_immediately
        current_active_scale = @r.scale
        @r.scale = {@current_scale_x, @current_scale_y}

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

        @r.scale = current_active_scale
      else
        push_cmd(DrawTextureCommand.new(
          z_index: z_index,
          texture: texture.to_sdl,
          source_rect: source_rect.try(&.to_sdl),
          dest_rect: actual_dest_rect.to_sdl,
          scale_x: @current_scale_x,
          scale_y: @current_scale_y,
          angle: angle.to_f64,
          center: center.to_sdl,
          flip: flip,
          tint: tint,
          destroy: destroy,
          clip_rect: @current_clip_rect,
          sort_y: sort_y
        ))
      end
    end

    def target=(texture : Texture?)
      @r.render_target = texture.try(&.to_sdl)
    end

    def target : Texture?
      if internal = @r.render_target
        Texture.new(internal)
      else
        nil
      end
    end

    def with_target(texture : Texture?)
      old_target = self.target
      self.target = texture
      yield
      self.target = old_target
    end

    def to_sdl
      @r
    end

    def vsync=(vsync : Int32)
      @r.vsync = vsync
    end
  end
end
