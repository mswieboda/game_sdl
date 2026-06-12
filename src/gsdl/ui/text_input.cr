require "./container"
require "./text"

module GSDL
  module UI
    class TextInput < Container
      property text : String = ""
      property placeholder : String = ""
      property max_length : Int32? = nil
      property mask_character : Char? = nil

      property on_change : Proc(String, Nil)? = nil
      property on_submit : Proc(String, Nil)? = nil

      property cursor_blink_rate : Float32 = 0.5_f32

      property border_color : Color
      property hover_border_color : Color
      property focus_border_color : Color
      property border_width : Int32 = 2

      property text_color : Color
      property placeholder_color : Color

      @cursor_position : Int32 = 0
      @blink_timer : Float32 = 0_f32
      @cursor_visible : Bool = false
      @text_offset_x : Int32 = 0

      @text_element : Text

      def initialize(
        text : String = "",
        @placeholder : String = "",
        @width : Int32 = 200,
        @height : Int32 = 40,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::TopLeft,
        @max_length : Int32? = nil,
        @mask_character : Char? = nil,
        background_color : Color | String = ColorScheme.get(:ui_bg, Color.parse("#1e1e24")),
        border_color : Color | String = ColorScheme.get(:border, Color.parse("#4b5563")),
        hover_border_color : Color | String = ColorScheme.get(:main, Color.parse("#10b981")),
        focus_border_color : Color | String = ColorScheme.get(:main, Color.parse("#10b981")),
        text_color : Color | String = ColorScheme.get(:ui_text, Color.parse("#f4f4f5")),
        placeholder_color : Color | String = Color.parse("#9ca3af"),
        font_size : Num = 16,
        padding : Spacing = Spacing.new(left: 8, right: 8, top: 4, bottom: 4),
        margin : Spacing = Spacing.new(all: 0),
        @flex : UInt8 = 0_u8,
        h_align : HorizontalAlign = HorizontalAlign::Left,
        v_align : VerticalAlign = VerticalAlign::Center,
        @on_change : Proc(String, Nil)? = nil,
        @on_submit : Proc(String, Nil)? = nil,
      )
        @text = text
        @cursor_position = text.size

        @background_color = background_color.is_a?(String) ? Color.parse(background_color) : background_color
        @border_color = border_color.is_a?(String) ? Color.parse(border_color) : border_color
        @hover_border_color = hover_border_color.is_a?(String) ? Color.parse(hover_border_color) : hover_border_color
        @focus_border_color = focus_border_color.is_a?(String) ? Color.parse(focus_border_color) : focus_border_color
        @text_color = text_color.is_a?(String) ? Color.parse(text_color) : text_color
        @placeholder_color = placeholder_color.is_a?(String) ? Color.parse(placeholder_color) : placeholder_color

        @focusable = true
        @clips_children = true
        @swallows_events = true

        # Create text label child
        @text_element = Text.new(
          text: @text.empty? ? @placeholder : @text,
          font_size: font_size,
          color: @text.empty? ? @placeholder_color : @text_color,
          width: FitContent,
          height: @height == FitContent ? FitContent : FillParent,
          h_align: h_align,
          v_align: v_align,
        )

        self.padding = padding
        self.margin = margin

        add_child(@text_element)
        update_text_scroll
      end

      # Expose constructor with blocks for on_submit callback
      def initialize(
        text : String = "",
        placeholder : String = "",
        width : Int32 = 200,
        height : Int32 = 40,
        x : Int32 = 0,
        y : Int32 = 0,
        anchor : Anchor = Anchor::TopLeft,
        max_length : Int32? = nil,
        mask_character : Char? = nil,
        background_color : Color | String = ColorScheme.get(:ui_bg, Color.parse("#1e1e24")),
        border_color : Color | String = ColorScheme.get(:border, Color.parse("#4b5563")),
        hover_border_color : Color | String = ColorScheme.get(:main, Color.parse("#10b981")),
        focus_border_color : Color | String = ColorScheme.get(:main, Color.parse("#10b981")),
        text_color : Color | String = ColorScheme.get(:ui_text, Color.parse("#f4f4f5")),
        placeholder_color : Color | String = Color.parse("#9ca3af"),
        font_size : Num = 16,
        padding : Spacing = Spacing.new(left: 8, right: 8, top: 4, bottom: 4),
        margin : Spacing = Spacing.new(all: 0),
        flex : UInt8 = 0_u8,
        h_align : HorizontalAlign = HorizontalAlign::Left,
        v_align : VerticalAlign = VerticalAlign::Center,
        on_change : Proc(String, Nil)? = nil,
        &block : String -> Nil
      )
        initialize(
          text: text,
          placeholder: placeholder,
          width: width,
          height: height,
          x: x,
          y: y,
          anchor: anchor,
          max_length: max_length,
          mask_character: mask_character,
          background_color: background_color,
          border_color: border_color,
          hover_border_color: hover_border_color,
          focus_border_color: focus_border_color,
          text_color: text_color,
          placeholder_color: placeholder_color,
          font_size: font_size,
          padding: padding,
          margin: margin,
          flex: flex,
          h_align: h_align,
          v_align: v_align,
          on_change: on_change,
          on_submit: block,
        )
      end

      def text=(val : String)
        return if @text == val
        @text = val
        @cursor_position = val.size
        update_text_scroll
        @on_change.try(&.call(@text))
      end

      def h_align : HorizontalAlign
        @text_element.align
      end

      def h_align=(align : HorizontalAlign)
        @text_element.align = align
      end

      def v_align : VerticalAlign
        @text_element.v_align
      end

      def v_align=(align : VerticalAlign)
        @text_element.v_align = align
      end

      def on_focus
        @cursor_visible = true
        @blink_timer = 0_f32
        Input.start_text_input
      end

      def on_unfocus
        @cursor_visible = false
        Input.stop_text_input
      end

      def update(dt : Float32)
        super(dt)

        if focused?
          @blink_timer += dt
          if @blink_timer >= @cursor_blink_rate
            @blink_timer -= @cursor_blink_rate
            @cursor_visible = !@cursor_visible
          end
        else
          @cursor_visible = false
        end
      end

      def on_text_input(event : GSDL::Event) : Bool
        new_chars = String.new(event.text.text)

        unless new_chars.empty?
          if max = @max_length
            remaining = max - @text.size
            if remaining <= 0
              return true
            end
            new_chars = new_chars[0...remaining] if new_chars.size > remaining
          end

          unless new_chars.empty?
            @text = @text[0...@cursor_position] + new_chars + @text[@cursor_position..]
            @cursor_position += new_chars.size
            @cursor_visible = true
            @blink_timer = 0_f32
            update_text_scroll
            @on_change.try(&.call(@text))
          end
        end

        true
      end

      def on_key_down(event : GSDL::Event) : Bool
        key = event.key.key

        if key == Keys::Backspace && @cursor_position > 0
          @text = @text[0...@cursor_position - 1] + @text[@cursor_position..]
          @cursor_position -= 1
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          @on_change.try(&.call(@text))
          return true
        elsif key == Keys::Delete && @cursor_position < @text.size
          @text = @text[0...@cursor_position] + @text[@cursor_position + 1..]
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          @on_change.try(&.call(@text))
          return true
        elsif key == Keys::Left && @cursor_position > 0
          @cursor_position -= 1
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          return true
        elsif key == Keys::Right && @cursor_position < @text.size
          @cursor_position += 1
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          return true
        elsif key == Keys::Home
          @cursor_position = 0
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          return true
        elsif key == Keys::End
          @cursor_position = @text.size
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          return true
        elsif key == Keys::Return
          @on_submit.try(&.call(@text))
          return true
        end

        false
      end

      private def update_text_scroll
        display_text = if mask = @mask_character
          mask.to_s * @text.size
        else
          @text
        end

        if @text.empty?
          @text_element.text = @placeholder
          @text_element.color = @placeholder_color
        else
          @text_element.text = display_text
          @text_element.color = @text_color
        end

        # Calculate cursor local X position (using display_text/mask_character)
        before_cursor = if mask = @mask_character
          mask.to_s * @cursor_position
        else
          @text[0...@cursor_position]
        end

        font_atlas = @text_element.text_entity.font_atlas
        char_spacing = @text_element.text_entity.character_spacing
        cursor_offset_x = font_atlas.calculate_width(before_cursor, char_spacing).to_i

        cw = content_width
        tw = @text_element.width

        if cw > 0
          if tw > cw
            if cursor_offset_x + @text_offset_x < 0
              @text_offset_x = -cursor_offset_x
            elsif cursor_offset_x + @text_offset_x > cw
              @text_offset_x = cw - cursor_offset_x
            end
          else
            @text_offset_x = case h_align
            when .center?
              (cw - tw) // 2
            when .right?
              cw - tw
            else
              0
            end
          end
        else
          @text_offset_x = 0
        end

        @text_element.x = @text_offset_x
      end

      def layout!
        super
        update_text_scroll
      end

      def draw(draw : Draw)
        return unless visible?
        layout! if @dirty_layout

        border_col = focused? ? @focus_border_color : (hovered? ? @hover_border_color : @border_color)

        rect = Rect.new(inner_x, inner_y, inner_width, inner_height)
        draw.rect_fill(rect, @background_color.not_nil!, effective_z_index)
        if @border_width > 0
          draw.rect_outline(rect, border_col, effective_z_index)
        end

        if clips_children?
          draw.push_clip(Rect.new(content_x, content_y, content_width, content_height))
          @children.each do |child|
            child.draw(draw) if child.visible?
          end

          if focused? && @cursor_visible
            # Calculate cursor visual X relative to text element
            before_cursor = if mask = @mask_character
              mask.to_s * @cursor_position
            else
              @text[0...@cursor_position]
            end

            font_atlas = @text_element.text_entity.font_atlas
            char_spacing = @text_element.text_entity.character_spacing
            cursor_offset_x = font_atlas.calculate_width(before_cursor, char_spacing).to_i

            if vp = viewport_ancestor
              cursor_offset_x = (cursor_offset_x * vp.zoom).to_i
            end

            cx = content_x + cursor_offset_x + (vp ? (@text_offset_x * vp.zoom).to_i : @text_offset_x)

            cursor_height = font_atlas.font_size.to_i
            cy_offset = case v_align
            when .top?
              0
            when .bottom?
              content_height - cursor_height
            else # Center
              (content_height - cursor_height) // 2
            end

            cy_top = content_y + cy_offset
            cy_bottom = cy_top + cursor_height

            draw.color = @text_color
            draw.line(cx, cy_top, cx, cy_bottom, z_index: effective_z_index + 2)
          end

          draw.pop_clip
        else
          @children.each do |child|
            child.draw(draw) if child.visible?
          end
        end
      end
    end
  end
end
