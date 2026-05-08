module GSDL
  enum HorizontalAlign
    Left
    Center
    Right
  end

  enum VerticalAlign
    Top
    Center
    Bottom
  end

  class TextBeta < Entity
    # include Centerable

    EllipsisMarker = "|^.~.^|"
    Ellipsis = "..."
    CharacterDefaultTypingSpeed = 0.075.seconds
    WordDefaultTypingSpeed = 0.25.seconds

    enum Typing
      None
      Character
      Word

      def typing_speed : Time::Span?
        case self
        when .character?
          CharacterDefaultTypingSpeed
        when .word?
          WordDefaultTypingSpeed
        else
          nil
        end
      end
    end

    property color : Color
    property z_index : Int32
    property h_align : HorizontalAlign
    property v_align : VerticalAlign
    property line_spacing : Num
    property character_spacing : Num
    property rotation : Num

    # TODO: make a setter to change font / font path
    getter font_size : Float32
    getter? width_fixed : Bool
    getter? height_fixed : Bool
    getter typing : Typing
    getter? typed : Bool

    @font_atlas : FontAtlas
    @full_text : String
    @width : Num?
    @height : Num?
    @lines : Array(String)
    @text_width : Float32?
    @typing_timer : Timer?

    def initialize(
      @font_atlas : FontAtlas,
      text : String = "foo",
      @x : Num = 0,
      @y : Num = 0,
      @h_align : HorizontalAlign = HorizontalAlign::Left,
      @v_align : VerticalAlign = VerticalAlign::Top,
      @line_spacing : Num = 1.2_f32,
      @character_spacing : Num = 0,
      @typing = Typing::None,
      typing_speed : Time::Span? = nil,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @rotation : Num = 0,
      @color = GSDL::Color::White,
      @width = nil,
      @height = nil,
      @z_index : Int32 = 0,
    )
      @font_size = @font_atlas.font_size
      @full_text = text
      @lines = [] of String

      @width_fixed = !@width.nil?
      @height_fixed = !@height.nil?

      unless typing_speed
        @typed = false
        typing_speed = @typing.typing_speed
        if speed = typing_speed
          @typing_timer = Timer.new(speed)
          @typing_timer.not_nil!.start
        end
      else
        @typed = true
      end

      update_lines
    end

    def text : String
      @lines.join("\n")
    end

    def text=(text : String)
      @full_text = text
      update_lines
    end

    def text_width : Float32
      if text_width = @text_width
        return text_width
      end

      max_line_width = 0_f32

      @lines.each do |line_text|
        line_width = @font_atlas.calculate_width(line_text, @character_spacing)

        if line_width > max_line_width
          max_line_width = line_width
        end
      end

      @text_width = max_line_width
      @text_width.not_nil!
    end

    def width : Num
      if width = @width
        return width
      end

      @width = text_width
      @width.not_nil!
    end

    def width=(width : Num?)
      if width != @width
        @width = width

        @width_fixed = !@width.nil?

        update_lines

        # reset height based on line changes, unless it's fixed
        if !height_fixed?
          self.height = nil
        end
      end
    end

    @[AlwaysInline]
    def line_height : Float32
      @font_size * @line_spacing
    end

    @[AlwaysInline]
    def text_height : Float32
      @font_size * @line_spacing * (@lines.size - 1) + @font_size
    end

    def height : Num
      if height = @height
        return height
      end

      @height = text_height
      @height.not_nil!
    end

    def height=(height : Num?)
      if height != @height
        @height = height

        @height_fixed = !@height.nil?

        update_lines
      end
    end

    @[AlwaysInline]
    def render_width : Num
      width * scale_x
    end

    @[AlwaysInline]
    def render_height : Num
      height * scale_y
    end

    def typing_speed : Time::Span?
      if timer = @typing_timer.duration
        timer.duration
      else
        nil
      end
    end

    def typing_speed=(typing_speed : TimeSpan?)
      if speed = typing_speed
        @typing_timer.duration = speed
      else
        @typing = Typing::None
      end
    end

    def update_lines
      if width = @width
        max_lines = Int32::MAX

        if height = @height
          max_lines = (height / line_height).to_i
        end

        @lines = [] of String
        all_lines = @full_text.lines

        all_lines.each_with_index do |text, index|
          # Check budget before even trying a new segment
          lines_left = max_lines - @lines.size
          break if lines_left <= 0

          # Check if this is the final piece of the entire string
          is_last_segment = (index == all_lines.size - 1)

          wrapped = wrap(text, width, lines_left, is_last_segment)

          # If we truncated, we stop immediately
          if wrapped.any?(&.ends_with?(EllipsisMarker))
            wrapped[-1] = wrapped[-1][0..-(EllipsisMarker.size + 1)] + Ellipsis
            @lines.concat(wrapped)
            break
          end

          @lines.concat(wrapped)
        end
      else
        @lines = @full_text.lines
      end
    end

    private def wrap(text : String, max_width : Num, remaining_lines : Int32, is_last_segment : Bool)
      words = text.split(' ')

      return [""] if words.all?(&.empty?)

      lines = [] of String
      current_line = [] of String
      current_width = 0.0_f32
      space_width = @font_atlas.calculate_width(" ")

      words.each_with_index do |word, index|
        word_width = @font_atlas.calculate_width(word, @character_spacing)
        is_last_word = (index == words.size - 1)

        # If single word is wider than max width
        if word_width > max_width
          lines << current_line.join(" ") unless current_line.empty?
          if lines.size >= remaining_lines
            lines[-1] = truncate(lines[-1] + EllipsisMarker, max_width)
          else
            lines << truncate(word, max_width)
          end

          return lines
        end

        # If word forces a wrap
        if !current_line.empty? && (current_width + word_width > max_width)
          # If no more lines are allowed, truncate the current content + this word
          if lines.size + 1 >= remaining_lines
            lines << truncate(current_line.join(" ") + " " + word, max_width)
            return lines
          end

          # Wrap
          lines << current_line.join(" ")
          current_line = [word]
          current_width = word_width + space_width
        else
          # Append
          current_line << word
          current_width += word_width + space_width
        end

        # Handle the end of the words
        if is_last_word
          line_text = current_line.join(" ")

          # If this is the last available line, but NOT the last segment
          # of the full text, we must truncate to show there is more content
          if lines.size + 1 >= remaining_lines && !is_last_segment
            lines << truncate(line_text, max_width)
          else
            lines << line_text
          end
        end
      end

      lines
    end

    private def truncate(text, max_width)
      return EllipsisMarker if @font_atlas.calculate_width(Ellipsis) > max_width

      # Binary search approach for better performance with long words
      low = 0
      high = text.size
      best_fit = ""

      while low <= high
        mid = (low + high) // 2
        candidate = text[0...mid]

        if @font_atlas.calculate_width(candidate + Ellipsis, @character_spacing) <= max_width
          best_fit = candidate
          low = mid + 1
        else
          high = mid - 1
        end
      end

      (best_fit.empty? ? "" : best_fit) + EllipsisMarker
    end

    private def calculate_visible_limit : Int32
      return @full_text.size if typed? || @typing.none?

      # How many "units" (chars or words) have been revealed
      elapsed_units = @full_text.size
      if timer = @typing_timer
        elapsed_units = timer.percent_infinite.to_i
      end

      case @typing
      when .character?
        elapsed_units
      when .word?
        # Find the character index where the Nth word ends
        count = 0

        @full_text.each_char_with_index do |char, i|
          if char.whitespace? || i >= @full_text.size - 1
            return i if count >= elapsed_units

            count += 1
          end
        end

        @full_text.size
      else
        @full_text.size
      end
    end

    def draw(draw : Draw)
      limit = calculate_visible_limit
      chars_processed = 0

      # Vertical Alignment
      offset_y = case @v_align
      when .center?
        [(self.height - text_height) / 2, 0].max
      when .bottom?
        [self.height - text_height, 0].max
      else
        0
      end

      @lines.each_with_index do |line_text, line_index|
        # Determine visibility for this specific line
        # We account for the \n that existed in @full_text but isn't in line_text
        line_limit = [limit - chars_processed, 0].max
        shown_text = line_text[0..[line_limit, line_text.size].min]

        if shown_text.size > 0 || line_text.empty?
          # Horizontal Alignment (full line_text for width)
          line_width = @font_atlas.calculate_width(line_text, @character_spacing)
          offset_x = case @h_align
          when .center?
            (self.width - line_width) / 2
          when .right?
            self.width - line_width
          else
            0
          end

          # Coordinate Calculation
          line_offset_y = line_index * line_height
          draw_x = @x + offset_x * scale_x - self.width * scale_x * origin_x
          draw_y = @y + offset_y * scale_y + line_offset_y * scale_y - (self.height * scale_y * origin_y)

          if @rotation % 360 == 0
            @font_atlas.draw_text(
              draw: draw,
              text: shown_text,
              x: draw_x.to_f32,
              y: draw_y.to_f32,
              character_spacing: @character_spacing,
              color: @color,
              scale_x: scale_x,
              scale_y: scale_y,
              z_index: @z_index
            )
          else
            anchor_x = @x
            anchor_y = @y

            base_offset_x = -(self.width * origin_x)
            base_offset_y = -(self.height * origin_y)

            # Combine base origin offset with alignment and line height
            # These are purely LOCAL to the pivot point.
            local_start_x = (base_offset_x + offset_x) * scale_x
            local_start_y = (base_offset_y + offset_y + (line_index * line_height)) * scale_y

            # Calculate the stationary rotation pivot point
            # pivot_x = @x - (self.width * scale_x * origin_x)
            # pivot_y = @y - (self.height * scale_y * origin_y)

            # These represent where the text starts RELATIVE to the pivot
            # We don't subtract origin here because we did it in the pivot_x/y calculation
            # relative_x = offset_x * scale_x
            # relative_y = (offset_y + (line_index * line_height)) * scale_y

            @font_atlas.draw_text_rotated(
              draw: draw,
              text: shown_text,
              pivot_x: anchor_x,
              pivot_y: anchor_y,
              start_x: local_start_x,
              start_y: local_start_y,
              rotation: @rotation,
              character_spacing: @character_spacing,
              color: @color,
              origin_x: origin_x,
              origin_y: origin_y,
              scale_x: scale_x,
              scale_y: scale_y,
              z_index: @z_index
            )
          end
        end

        # Update progress (+1 accounts for the stripped newline character)
        chars_processed += line_text.size + 1

        # Early exit if we've reached the typing limit
        if chars_processed > limit && !typed?
          # Check if we literally just finished the last character
          if line_index == @lines.size - 1 && shown_text.size == line_text.size
            @typed = true
          end

          return
        end
      end
    end
  end
end
