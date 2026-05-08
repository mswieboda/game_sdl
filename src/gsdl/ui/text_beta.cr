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

    property color : Color
    property z_index : Int32
    property h_align : HorizontalAlign
    property v_align : VerticalAlign
    property line_spacing : Num
    property character_spacing : Num

    # TODO: make a setter to change font / font path
    getter font_size : Float32
    getter? width_fixed : Bool
    getter? height_fixed : Bool

    @font_atlas : FontAtlas
    @full_text : String
    @width : Num?
    @height : Num?
    @lines : Array(String)
    @text_width : Float32?

    def initialize(
      @font_atlas : FontAtlas,
      text : String = "foo",
      @x : Num = 0,
      @y : Num = 0,
      @h_align : HorizontalAlign = HorizontalAlign::Left,
      @v_align : VerticalAlign = VerticalAlign::Top,
      @line_spacing : Num = 1.2_f32,
      @character_spacing : Num = 0,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
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

    def draw(draw : Draw)
      offset_y = case @v_align
      when .top?
        0
      when .center?
        [self.height / 2 - text_height / 2, 0].max
      when .bottom?
        [self.height - text_height, 0].max
      else
        0
      end

      @lines.each_with_index do |line_text, line_index|
        line_width = @font_atlas.calculate_width(line_text, @character_spacing)
        offset_x = 0

        if width = @width
          offset_x = case @h_align
          when .left?
            0
          when .center?
            width / 2 - line_width / 2
          when .right?
            width - line_width
          else
            0
          end
        end

        line_offset_y = line_index * line_height

        x = @x + offset_x * scale_x - (self.width * scale_x * origin_x)
        y = @y + offset_y * scale_y + line_offset_y * scale_y - (self.height * scale_y * origin_y)

        @font_atlas.draw_text(
          text: line_text,
          x: x.to_f32,
          y: y.to_f32,
          character_spacing: @character_spacing,
          color: @color,
          scale_x: scale_x,
          scale_y: scale_y,
          z_index: @z_index
        )
      end
    end
  end
end
