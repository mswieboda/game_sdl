require "./element"

module GSDL
  module UI
    class Image < Element
      property texture : Texture?

      def initialize(
        id : Symbol | Texture | Nil = nil,
        @width : Int32 = FitContent,
        @height : Int32 = FitContent,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::TopLeft,
        @z_index : Int32 = 0,
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
          dest = FRect.new(
            x: content_x.to_f32,
            y: content_y.to_f32,
            w: content_width.to_f32,
            h: content_height.to_f32
          )
          draw.texture(
            texture: tex,
            dest_rect: dest,
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
