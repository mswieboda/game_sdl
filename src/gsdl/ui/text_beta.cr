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

    property z_index : Int32
    property h_align : HorizontalAlign
    property v_align : VerticalAlign
    property line_spacing : Num

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
      font_path = "./assets/fonts/PressStart2P.ttf",
      @font_size : Float32 = 16_f32, # TODO: maybe make this a Num or Int32
      text : String = "foo",
      @x : Num = 0,
      @y : Num = 0,
      @h_align : HorizontalAlign = HorizontalAlign::Left,
      @v_align : VerticalAlign = VerticalAlign::Top,
      @line_spacing : Num = 1.2_f32,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @color = GSDL::Color::White,
      @width = nil,
      @height = nil,
      @z_index : Int32 = 0,
    )
      @font_atlas = GSDL::FontAtlas.new(font_path, @font_size)
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
        line_width = @font_atlas.calculate_width(line_text)

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

        @full_text.lines.each do |text|
          break if @lines.size >= max_lines

          wrapped = wrap(text, width, max_lines - @lines.size)

          @lines.concat(wrapped)
        end

        # @lines = @full_text.lines.flat_map do |text|
        #   wrap(text, width)
        # end
      else
        @lines = @full_text.lines
      end
    end

    private def wrap(text : String, max_width : Num, remaining_lines : Int32)
      words = text.split(' ')

      return [""] if words.all?(&.empty?)

      space_width = @font_atlas.calculate_width(" ")

      lines = [] of String
      current_line = [] of String
      current_width = 0.0_f32

      words.each_with_index do |word, index|
        word_width = @font_atlas.calculate_width(word)

        # If adding this word exceeds width, flush current_line
        if !current_line.empty? && (current_width + word_width > max_width)
          # If we are on the very last line allowed, we must truncate this line instead of wrapping
          if lines.size + 1 >= remaining_lines
            truncated_line = truncate(current_line.join(" ") + " " + word, max_width)
            lines << truncated_line

            # Stop processing words entirely
            return lines
          end

          lines << current_line.join(" ")
          current_line = [] of String
          current_width = 0.0_f32
        end

        current_line << word
        current_width += word_width + space_width
      end

      # Handle the final leftover line
      if !current_line.empty?
        final_text = current_line.join(" ")

        if lines.size >= remaining_lines || @font_atlas.calculate_width(final_text) > max_width
          final_text = truncate(final_text, max_width)
        end

        lines << final_text
      end

      lines
    end

    private def truncate(text, max_width)
      ellipsis = "..."
      e_width = @font_atlas.calculate_width(ellipsis)

      # If even the ellipsis doesn't fit, just return an empty string or a dot
      return "" if e_width > max_width

      # Start dropping characters from the end
      i = text.size

      while i > 0
        candidate = text[0...i] + ellipsis

        return candidate if @font_atlas.calculate_width(candidate) <= max_width

        i -= 1
      end

      ellipsis
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
        line_width = @font_atlas.calculate_width(line_text)
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
          color: @color,
          scale_x: scale_x,
          scale_y: scale_y,
          z_index: @z_index
        )
      end
    end
  end
end
