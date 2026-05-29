require "./element"

module GSDL
  module UI
    class Text < Element
      getter text_entity : GSDL::Text
      @original_font_size : Float32

      def initialize(
        font : Symbol = :default,
        text : String = "",
        font_size : Num = 16_f32,
        @x : Int32 = 0,
        @y : Int32 = 0,
        color = ColorScheme.get(:ui_text),
        h_align : HorizontalAlign = HorizontalAlign::Left,
        v_align : VerticalAlign = VerticalAlign::Top,
        @anchor : Anchor = Anchor::TopLeft,
        width : Int32? = nil,
        height : Int32? = nil,
        @z_index : Int32 = 0,
        @flex : UInt8 = 1_u8,
        opacity : UInt8 = 255_u8,
        weight : FontWeight = FontWeight::Normal,
        style : FontStyle = FontStyle::Regular,
        @padding = Spacing.new(all: 0),
        @margin = Spacing.new(all: 0),
      )
        @width = width || FitContent
        @height = height || FitContent
        @original_font_size = font_size.to_f32
        @text_entity = GSDL::Text.new(
          font: font,
          font_size: font_size,
          text: text,
          h_align: h_align,
          v_align: v_align,
          color: color,
          width: resolved_width,
          height: resolved_height,
          z_index: z_index,
          weight: weight,
          style: style,
          draw_relative_to_camera: false
        )
        @text_entity.opacity = opacity
      end

      def text : String
        @text_entity.text
      end

      def font : Symbol
        @text_entity.font
      end

      def font_size : Num
        @original_font_size
      end

      def color : Color
        @text_entity.color
      end

      def color=(color : Color)
        @text_entity.color = color
      end

      def z_index : Int32
        @text_entity.z_index
      end

      def z_index=(z : Int32)
        @text_entity.z_index = z
      end

      def opacity : UInt8
        @text_entity.opacity
      end

      def opacity=(op : UInt8)
        @text_entity.opacity = op
      end

      def weight : FontWeight
        @text_entity.weight
      end

      def weight=(w : FontWeight)
        @text_entity.weight = w
      end

      def style : FontStyle
        @text_entity.style
      end

      def style=(s : FontStyle)
        @text_entity.style = s
      end

      def text=(text : String)
        return if @text_entity.text == text
        @text_entity.text = text
        notify_size_changed
      end

      def font=(font : Symbol)
        return if @text_entity.font == font
        @text_entity.font = font
        notify_size_changed
      end

      def font_size=(size : Num)
        return if @original_font_size == size.to_f32
        @original_font_size = size.to_f32
        @text_entity.font_size = size
        notify_size_changed
      end

      def align : HorizontalAlign
        @text_entity.h_align
      end

      def align=(align : HorizontalAlign)
        return if @text_entity.h_align == align
        @text_entity.h_align = align
        notify_size_changed
      end

      def v_align : VerticalAlign
        @text_entity.v_align
      end

      def v_align=(align : VerticalAlign)
        return if @text_entity.v_align == align
        @text_entity.v_align = align
        notify_size_changed
      end

      def width=(width : Int32)
        super
        @text_entity.width = resolved_width
      end

      def height=(height : Int32)
        super
        @text_entity.height = resolved_height
      end

      def set_layout_width(width : Int32)
        super
        @text_entity.width = resolved_width
      end

      def set_layout_height(height : Int32)
        super
        @text_entity.height = resolved_height
      end

      def width : Int32
        w = @width
        if w == FitContent
          @text_entity.width.to_f.ceil.to_i
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
          @text_entity.height.to_f.ceil.to_i
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

        # 1. Dynamically scale the font size and bounds of the text entity on-the-fly
        if vp = viewport_ancestor
          @text_entity.font_size = @original_font_size * vp.zoom
          # Scale the text entity wrapping width/height if set
          @text_entity.width = resolved_width.try { |w| (w * vp.zoom).to_i }
          @text_entity.height = resolved_height.try { |h| (h * vp.zoom).to_i }
        else
          @text_entity.font_size = @original_font_size
          @text_entity.width = resolved_width
          @text_entity.height = resolved_height
        end

        # Draw background first if background_color is set
        draw_background(draw)

        # Position the text entity exactly where we are drawing
        # content_x and content_y already account for parent and padding/margins
        @text_entity.x = content_x
        @text_entity.y = content_y
        @text_entity.z_index = effective_z_index

        # Render the text entity
        @text_entity.draw(draw)
      end

      private def notify_size_changed
        dirty_position!
        if p = @parent
          p.dirty_layout! if p.is_a?(Container)
        end
      end

      private def resolved_width : Int32?
        w = @width
        if w == FitContent
          nil
        elsif w == FillParent
          if p = @parent
            p.width_fixed? ? (p.width - @margin.horizontal - @padding.horizontal) : nil
          else
            nil
          end
        else
          w
        end
      end

      private def resolved_height : Int32?
        h = @height
        if h == FitContent
          nil
        elsif h == FillParent
          if p = @parent
            p.height_fixed? ? (p.height - @margin.vertical - @padding.vertical) : nil
          else
            nil
          end
        else
          h
        end
      end
    end
  end
end
