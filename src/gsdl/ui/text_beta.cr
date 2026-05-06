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

    def width=(width : Num)
      puts ">>> width=(#{width}) @width=#{@width}"
      if width != @width
        @width = width

        update_lines
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

    def height=(height : Num)
      if height != @height
        @height = height

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
      puts ">>> update_lines w: #{@width}"
      segments = @full_text.split("\n")

      # puts ">>> segments: `#{segments}`"

      if width = @width
        current_line_width = 0.0_f32

        @lines = [] of String
        line = [] of String

        segments.each_with_index do |segment, segment_index|
          # puts ">>> segment: `#{segment}`"

          words = segment.split(' ')

          # puts ">>> words: `#{words}` all empty?: #{words.all?(&.empty?)}"

          # If all words are empty, it was a new line (with potential spaces)
          if words.all?(&.empty?)
            @lines << ""
            next
          end

          words.each_with_index do |word, word_index|
            # puts ">>> word: `#{word}` #{typeof(word)} empty?: #{word.empty?}"

            # Measure the word (plus a space)
            word_width = @font_atlas.calculate_width(word + " ")

            # Check if this word pushes us over the boundary
            if current_line_width + word_width > width
              # puts ">>> LAST WORD FOR LENGTH word: `#{word}`"
              # puts ">>> line to add: `#{line}`"
              # Add the current line
              @lines << line.join(" ")

              # Start the next line
              line = [word]
              current_line_width = word_width

              # puts ">>> @lines: `#{@lines}`"
            else
              # Add word to the line
              # puts ">>> ADD WORD word: `#{word}`"
              line << word
              # puts ">>> line: `#{line}`"
              current_line_width += word_width
            end

            # Check if this was the last word in the segment
            if word_index >= words.size - 1
              # Add the current line
              # puts ">>> LAST WORD FOR WORDS word: `#{word}`"
              # puts ">>> line: `#{line}`"
              @lines << line.join(" ")
              # puts ">>> @lines: `#{@lines}`"
              line = [] of String
              current_line_width = 0_f32
            end
          end

          # Check if this was the last segment
          if segment_index >= segments.size - 1 && !line.empty?
            # puts ">>> LAST SEGMENT line: `#{line}`"
            # puts ">>> line to add: `#{line}`"
            # Add the current line
            @lines << line.join(" ")
            # puts ">>> @lines: `#{@lines}`"
            current_line_width = 0_f32
          end

          # puts ">>>"
        end
      else
        @lines = segments
      end
    end

    def draw(draw : Draw)
      offset_y = case @v_align
      when .top?
        0
      when .center?
        self.height / 2 - text_height / 2
      when .bottom?
        self.height - text_height
        0
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
