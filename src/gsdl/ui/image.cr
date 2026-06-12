require "./element"

module GSDL
  module UI
    enum ResizeMode
      Stretch
      Contain
      Cover
      Center
      None
    end

    class Image < Element
      property texture : Texture?
      property resize_mode : ResizeMode = ResizeMode::Center

      def initialize(
        id : Symbol | Texture | Nil = nil,
        @resize_mode : ResizeMode = ResizeMode::Center,
        @width : Int32 = FitContent,
        @height : Int32 = FitContent,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::TopLeft,
        @z_index : Int32 = 0,
        @padding = Spacing.new(all: 0),
        @margin = Spacing.new(all: 0),
        @flex : UInt8 = 0_u8,
      )
        if id.is_a?(Symbol)
          @texture = TextureManager.get(id)
        elsif id.is_a?(Texture)
          @texture = id
        end
      end

      def texture=(id : Symbol)
        @texture = TextureManager.get(id)
        notify_size_changed
      end

      def texture=(texture : Texture)
        @texture = texture
        notify_size_changed
      end

      def width : Int32
        w = @width
        if w == FitContent
          @texture ? @texture.not_nil!.width.to_i : 0
        elsif w == FillParent
          if p = @parent
            p.width_fixed? ? (p.width - @margin.horizontal - @padding.horizontal) : 0
          else
            0
          end
        else
          w
        end
      end

      def height : Int32
        h = @height
        if h == FitContent
          @texture ? @texture.not_nil!.height.to_i : 0
        elsif h == FillParent
          if p = @parent
            p.height_fixed? ? (p.height - @margin.vertical - @padding.vertical) : 0
          else
            0
          end
        else
          h
        end
      end

      def draw(draw : Draw)
        return unless visible?

        # 1. Draw background first if background_color is set
        draw_background(draw)

        # 2. Draw texture if present
        if tex = @texture
          tw = tex.width.to_f32
          th = tex.height.to_f32
          cw = content_width.to_f32
          ch = content_height.to_f32
          cx = content_x.to_f32
          cy = content_y.to_f32

          source_rect = nil
          dest_rect = FRect.new(cx, cy, cw, ch)

          case @resize_mode
          when ResizeMode::Stretch
            source_rect = FRect.new(0.0_f32, 0.0_f32, tw, th)
            dest_rect = FRect.new(cx, cy, cw, ch)

          when ResizeMode::Contain
            scale = Math.min(cw / tw, ch / th)
            nw = tw * scale
            nh = th * scale
            source_rect = FRect.new(0.0_f32, 0.0_f32, tw, th)
            dest_rect = FRect.new(cx + (cw - nw) / 2.0_f32, cy + (ch - nh) / 2.0_f32, nw, nh)

          when ResizeMode::Cover
            scale = Math.max(cw / tw, ch / th)
            sw = cw / scale
            sh = ch / scale
            sx = (tw - sw) / 2.0_f32
            sy = (th - sh) / 2.0_f32
            source_rect = FRect.new(sx, sy, sw, sh)
            dest_rect = FRect.new(cx, cy, cw, ch)

          when ResizeMode::Center
            sw = Math.min(tw, cw)
            sh = Math.min(th, ch)
            sx = (tw - sw) / 2.0_f32
            sy = (th - sh) / 2.0_f32
            source_rect = FRect.new(sx, sy, sw, sh)
            dest_rect = FRect.new(cx + (cw - sw) / 2.0_f32, cy + (ch - sh) / 2.0_f32, sw, sh)

          when ResizeMode::None
            sw = Math.min(tw, cw)
            sh = Math.min(th, ch)
            source_rect = FRect.new(0.0_f32, 0.0_f32, sw, sh)
            dest_rect = FRect.new(cx, cy, sw, sh)
          end

          draw.texture(
            texture: tex,
            source_rect: source_rect,
            dest_rect: dest_rect,
            z_index: effective_z_index
          )
        end
      end

      private def notify_size_changed
        dirty_position!
        if p = @parent
          p.dirty_layout! if p.is_a?(Container)
        end
      end
    end
  end
end
