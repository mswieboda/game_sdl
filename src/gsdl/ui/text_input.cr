require "./container"
require "./text"

module GSDL
  module UI
    class TextInput < Container
      IS_MAC = {% if flag?(:darwin) %} true {% else %} false {% end %}

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
      property selection_color : Color

      @cursor_position : Int32 = 0
      @selection_anchor : Int32 = 0
      @mouse_dragging : Bool = false
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
        selection_color : Color | String = Color.new(14, 165, 233, 102),
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
        @selection_anchor = text.size

        @background_color = background_color.is_a?(String) ? Color.parse(background_color) : background_color
        @border_color = border_color.is_a?(String) ? Color.parse(border_color) : border_color
        @hover_border_color = hover_border_color.is_a?(String) ? Color.parse(hover_border_color) : hover_border_color
        @focus_border_color = focus_border_color.is_a?(String) ? Color.parse(focus_border_color) : focus_border_color
        @text_color = text_color.is_a?(String) ? Color.parse(text_color) : text_color
        @placeholder_color = placeholder_color.is_a?(String) ? Color.parse(placeholder_color) : placeholder_color
        @selection_color = selection_color.is_a?(String) ? Color.parse(selection_color) : selection_color

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
        @text_element.z_index = 1

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
        selection_color : Color | String = Color.new(14, 165, 233, 102),
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
          selection_color: selection_color,
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
        @selection_anchor = val.size
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
        @mouse_dragging = false
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

          if @mouse_dragging
            if Mouse.pressed?(Mouse::ButtonLeft)
              mouse_x = Mouse.x
              local_x = get_local_mouse_x(mouse_x)
              idx = find_char_index_at(local_x)
              @cursor_position = idx
              update_text_scroll
            else
              @mouse_dragging = false
            end
          end
        else
          @cursor_visible = false
          @mouse_dragging = false
        end
      end

      def on_mouse_down(event : GSDL::Event) : Bool
        request_focus

        if Mouse.double_tap?(Mouse::ButtonLeft)
          mouse_x = Mouse.x
          local_x = get_local_mouse_x(mouse_x)
          idx = find_char_index_at(local_x)
          select_word_at(idx)
        else
          mouse_x = Mouse.x
          local_x = get_local_mouse_x(mouse_x)
          idx = find_char_index_at(local_x)
          @cursor_position = idx
          @selection_anchor = idx
          @mouse_dragging = true
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
        end

        true
      end

      def on_mouse_move(event : GSDL::Event) : Bool
        # Handled in the update loop to support continuous drag outside boundaries
        true
      end

      def on_mouse_up(event : GSDL::Event) : Bool
        @mouse_dragging = false
        true
      end

      def on_text_input(event : GSDL::Event) : Bool
        new_chars = String.new(event.text.text)

        unless new_chars.empty?
          if selection_active?
            delete_selection
          end

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
            @selection_anchor = @cursor_position
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

        shift_pressed = Keys.pressed?(Keys::LShift) || Keys.pressed?(Keys::RShift) || (event.key.mod.to_i & 0x0003) != 0
        gui_pressed = (event.key.mod.to_i & 0x0C00) != 0
        ctrl_pressed = (event.key.mod.to_i & 0x00C0) != 0

        # Select All (Cmd + A or Ctrl + A)
        if (gui_pressed || ctrl_pressed) && key == Keys::A
          @selection_anchor = 0
          @cursor_position = @text.size
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          return true
        end

        # Copy (Cmd + C or Ctrl + C)
        if (gui_pressed || ctrl_pressed) && key == Keys::C
          if selection_active?
            start_idx, end_idx = selection_range
            selected_text = @text[start_idx...end_idx]
            SDL3::Clipboard.text = selected_text
          end
          return true
        end

        # Cut (Cmd + X or Ctrl + X)
        if (gui_pressed || ctrl_pressed) && key == Keys::X
          if selection_active?
            start_idx, end_idx = selection_range
            selected_text = @text[start_idx...end_idx]
            SDL3::Clipboard.text = selected_text
            delete_selection
            @cursor_visible = true
            @blink_timer = 0_f32
            update_text_scroll
            @on_change.try(&.call(@text))
          end
          return true
        end

        # Paste (Cmd + V or Ctrl + V)
        if (gui_pressed || ctrl_pressed) && key == Keys::V
          if SDL3::Clipboard.has_text?
            clip_text = SDL3::Clipboard.text.gsub("\n", "").gsub("\r", "")
            unless clip_text.empty?
              if selection_active?
                delete_selection
              end

              if max = @max_length
                remaining = max - @text.size
                if remaining <= 0
                  return true
                end
                clip_text = clip_text[0...remaining] if clip_text.size > remaining
              end

              unless clip_text.empty?
                @text = @text[0...@cursor_position] + clip_text + @text[@cursor_position..]
                @cursor_position += clip_text.size
                @selection_anchor = @cursor_position
                @cursor_visible = true
                @blink_timer = 0_f32
                update_text_scroll
                @on_change.try(&.call(@text))
              end
            end
          end
          return true
        end

        if key == Keys::Backspace
          if selection_active?
            delete_selection
            @cursor_visible = true
            @blink_timer = 0_f32
            update_text_scroll
            @on_change.try(&.call(@text))
            return true
          elsif @cursor_position > 0
            @text = @text[0...@cursor_position - 1] + @text[@cursor_position..]
            @cursor_position -= 1
            @selection_anchor = @cursor_position
            @cursor_visible = true
            @blink_timer = 0_f32
            update_text_scroll
            @on_change.try(&.call(@text))
            return true
          end
        elsif key == Keys::Delete
          if selection_active?
            delete_selection
            @cursor_visible = true
            @blink_timer = 0_f32
            update_text_scroll
            @on_change.try(&.call(@text))
            return true
          elsif @cursor_position < @text.size
            @text = @text[0...@cursor_position] + @text[@cursor_position + 1..]
            @selection_anchor = @cursor_position
            @cursor_visible = true
            @blink_timer = 0_f32
            update_text_scroll
            @on_change.try(&.call(@text))
            return true
          end
        elsif key == Keys::Left
          alt_pressed = (event.key.mod.to_i & 0x0300) != 0

          # On Mac: Alt+Left jumps previous word, Cmd+Left jumps to start
          # On other OS: Ctrl+Left jumps previous word
          word_jump = IS_MAC ? alt_pressed : ctrl_pressed
          line_jump = IS_MAC && gui_pressed

          new_pos = if line_jump
            0
          elsif word_jump
            find_prev_word_boundary
          else
            if shift_pressed
              Math.max(0, @cursor_position - 1)
            else
              if selection_active?
                selection_range[0]
              else
                Math.max(0, @cursor_position - 1)
              end
            end
          end

          @cursor_position = new_pos
          unless shift_pressed
            @selection_anchor = @cursor_position
          end
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          return true
        elsif key == Keys::Right
          alt_pressed = (event.key.mod.to_i & 0x0300) != 0

          # On Mac: Alt+Right jumps next word, Cmd+Right jumps to end
          # On other OS: Ctrl+Right jumps next word
          word_jump = IS_MAC ? alt_pressed : ctrl_pressed
          line_jump = IS_MAC && gui_pressed

          new_pos = if line_jump
            @text.size
          elsif word_jump
            find_next_word_boundary
          else
            if shift_pressed
              Math.min(@text.size, @cursor_position + 1)
            else
              if selection_active?
                selection_range[1]
              else
                Math.min(@text.size, @cursor_position + 1)
              end
            end
          end

          @cursor_position = new_pos
          unless shift_pressed
            @selection_anchor = @cursor_position
          end
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          return true
        elsif key == Keys::Home
          @cursor_position = 0
          unless shift_pressed
            @selection_anchor = 0
          end
          @cursor_visible = true
          @blink_timer = 0_f32
          update_text_scroll
          return true
        elsif key == Keys::End
          @cursor_position = @text.size
          unless shift_pressed
            @selection_anchor = @text.size
          end
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

      private def selection_active? : Bool
        @selection_anchor != @cursor_position
      end

      private def selection_range : {Int32, Int32}
        start_idx = Math.min(@selection_anchor, @cursor_position)
        end_idx = Math.max(@selection_anchor, @cursor_position)
        {start_idx, end_idx}
      end

      private def delete_selection
        return unless selection_active?
        start_idx, end_idx = selection_range
        @text = @text[0...start_idx] + @text[end_idx..]
        @cursor_position = start_idx
        @selection_anchor = start_idx
      end

      private def select_word_at(index : Int32)
        return if @text.empty?
        start_pos = index
        end_pos = index

        while start_pos > 0 && word_char?(@text[start_pos - 1])
          start_pos -= 1
        end

        while end_pos < @text.size && word_char?(@text[end_pos])
          end_pos += 1
        end

        @selection_anchor = start_pos
        @cursor_position = end_pos
        update_text_scroll
      end

      private def word_char?(char : Char) : Bool
        char.alphanumeric? || char == '_'
      end

      private def find_prev_word_boundary : Int32
        pos = @cursor_position
        return 0 if pos <= 0

        # Skip non-word characters to the left
        while pos > 0 && !word_char?(@text[pos - 1])
          pos -= 1
        end

        # Skip word characters to the left
        while pos > 0 && word_char?(@text[pos - 1])
          pos -= 1
        end

        pos
      end

      private def find_next_word_boundary : Int32
        pos = @cursor_position
        len = @text.size
        return len if pos >= len

        # Skip non-word characters to the right
        while pos < len && !word_char?(@text[pos])
          pos += 1
        end

        # Skip word characters to the right
        while pos < len && word_char?(@text[pos])
          pos += 1
        end

        pos
      end

      private def get_local_mouse_x(mouse_x : Int32) : Int32
        content_x = self.content_x
        if vp = viewport_ancestor
          ((mouse_x - content_x) / vp.zoom).to_i - @text_offset_x
        else
          mouse_x - content_x - @text_offset_x
        end
      end

      private def find_char_index_at(local_x : Int32) : Int32
        display_text = if mask = @mask_character
          mask.to_s * @text.size
        else
          @text
        end

        return 0 if display_text.empty?

        font_atlas = @text_element.text_entity.font_atlas
        char_spacing = @text_element.text_entity.character_spacing

        best_index = 0
        best_diff = local_x.abs

        (1..display_text.size).each do |i|
          sub = display_text[0...i]
          width = font_atlas.calculate_width(sub, char_spacing).to_i
          diff = (local_x - width).abs
          if diff < best_diff
            best_diff = diff
            best_index = i
          end
        end

        best_index
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

          # Render selection highlight block behind text element
          if focused? && selection_active?
            sel_start, sel_end = selection_range

            before_start = if mask = @mask_character
              mask.to_s * sel_start
            else
              @text[0...sel_start]
            end

            before_end = if mask = @mask_character
              mask.to_s * sel_end
            else
              @text[0...sel_end]
            end

            font_atlas = @text_element.text_entity.font_atlas
            char_spacing = @text_element.text_entity.character_spacing

            x_start = font_atlas.calculate_width(before_start, char_spacing).to_i
            x_end = font_atlas.calculate_width(before_end, char_spacing).to_i

            if vp = viewport_ancestor
              x_start = (x_start * vp.zoom).to_i
              x_end = (x_end * vp.zoom).to_i
            end

            cx_offset = (vp ? (@text_offset_x * vp.zoom).to_i : @text_offset_x)
            highlight_x = content_x + x_start + cx_offset
            highlight_w = x_end - x_start

            cursor_height = font_atlas.font_size.to_i
            cy_offset = case v_align
            when .top?
              0
            when .bottom?
              content_height - cursor_height
            else # Center
              (content_height - cursor_height) // 2
            end

            highlight_y = content_y + cy_offset

            highlight_rect = Rect.new(highlight_x, highlight_y, highlight_w, cursor_height)
            draw.rect_fill(highlight_rect, @selection_color, effective_z_index + 1)
          end

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
            draw.line(cx, cy_top, cx, cy_bottom, z_index: effective_z_index + 3)
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
