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

  class Text < Entity
    include Centerable

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

    property z_index : Int32
    property h_align : HorizontalAlign
    property v_align : VerticalAlign
    property line_spacing : Num
    property character_spacing : Num
    property shadow : {Num, Num}
    property shadow_color : Color
    property outline : Int32
    property outline_color : Color
    property? draw_relative_to_camera : Bool

    getter color : Color
    getter? width_fixed : Bool
    getter? height_fixed : Bool
    getter typing : Typing
    getter? typed : Bool
    getter font_atlas : Font
    property on_complete : Proc(Nil) | Nil = nil

    @vertices_main = Array(GSDL::Vertex).new
    @vertices_outline = Array(GSDL::Vertex).new
    @vertices_shadow = Array(GSDL::Vertex).new
    @indices = Array(Int32).new(initial_capacity: 600) # Space for 100 chars
    @dirty = true
    @last_visible_limit = -1

    # TODO: make a setter to change font atlas
    @font_atlas : Font
    @outline_atlas : Font?
    @full_text : String
    @width : Num?
    @height : Num?
    @original_width : Num?
    @original_height : Num?
    @lines : Array(String)
    @text_width : Float32?
    @typing_timer : Timer?
    @rotation : Num

    def initialize(
      font : String = FontManager.default,
      font_size : Num = FontManager.default_size,
      text : String = "",
      @x : Num = 0,
      @y : Num = 0,
      @h_align : HorizontalAlign = HorizontalAlign::Left,
      @v_align : VerticalAlign = VerticalAlign::Top,
      @line_spacing : Num = 1.2_f32,
      @character_spacing : Num = 0,
      @typing = Typing::None,
      typing_speed : Time::Span? = nil,
      @shadow = {0, 0},
      @shadow_color : Color = Color::Black,
      @outline : Int32 = FontManager.default_outline,
      @outline_color : Color = Color::Black,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @rotation : Num = 0,
      @color = GSDL::Color::White,
      @width = nil,
      @height = nil,
      @z_index : Int32 = 0,
      @draw_relative_to_camera : Bool = true,
      @weight : FontWeight = FontWeight::Normal,
      @style : FontStyle = FontStyle::Regular,
    )
      @font = font
      @font_atlas = FontManager.get(@font, font_size, 0, @weight, @style)
      @outline_atlas = nil

      @full_text = text
      @lines = [] of String

      @width_fixed = !@width.nil?
      @height_fixed = !@height.nil?

      @original_width = @width
      @original_height = @height

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

    def z_index_max
      z_index = @z_index

      if @outline > 0
        z_index += 1
      end

      if !@shadow.all?(&.zero?)
        z_index += 1
      end

      z_index
    end

    @[AlwaysInline]
    def font_size : Num
      @font_atlas.font_size
    end

    def font : String
      @font
    end

    def font=(font : String)
      if font != @font
        @font = font
        @font_atlas = FontManager.get(@font, font_size, 0, @weight, @style)
        @dirty = true
      end
    end

    def weight : FontWeight
      @weight
    end

    def weight=(weight : FontWeight)
      if weight != @weight
        @weight = weight
        @font_atlas = FontManager.get(@font, font_size, 0, @weight, @style)
        @dirty = true
      end
    end

    def style : FontStyle
      @style
    end

    def style=(style : FontStyle)
      if style != @style
        @style = style
        @font_atlas = FontManager.get(@font, font_size, 0, @weight, @style)
        @dirty = true
      end
    end

    @[AlwaysInline]
    def text : String
      @lines.join("\n")
    end

    def text=(text : String)
      @dirty = true
      @width = @original_width
      @height = @original_height
      @full_text = text
      update_lines
      restart if !@typing.none?
    end

    def wrap_width=(val : Num?)
      self.width = val
    end

    def complete? : Bool
      return true if typed? || @typing.none?

      if timer = @typing_timer
        elapsed_units = timer.percent_infinite.to_i
        if @typing.character?
          return elapsed_units >= @full_text.size
        elsif @typing.word?
          total_words = @full_text.split(/\s+/).size
          return elapsed_units >= total_words
        end
      end

      true
    end

    def complete
      @typed = true
      @typing_timer.try(&.stop)
      @on_complete.try(&.call)
    end

    def restart
      @typed = false
      @typing_timer.try(&.restart)
    end

    def update(dt : Float32) : Bool
      return false unless super(dt)

      if !typed? && !@typing.none? && complete?
        @typed = true
        @on_complete.try(&.call)
      end

      true
    end

    def text_width : Float32
      if !@dirty && (text_width = @text_width)
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
        @dirty = true
        @width = width
        @original_width = @width

        @width_fixed = !@width.nil?

        update_lines

        # reset height based on line changes, unless it's fixed
        if !height_fixed?
          self.height = nil
        end
      end
    end

    @[AlwaysInline]
    def line_height : Num
      font_size * @line_spacing
    end

    @[AlwaysInline]
    def text_height : Num
      font_size * @line_spacing * (@lines.size - 1) + font_size
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
        @dirty = true
        @height = height
        @original_height = @height

        @height_fixed = !@height.nil?

        update_lines
      end
    end

    def rotation : Num
      @rotation
    end

    def rotation=(rotation : Num)
      @dirty = true
      @rotation = rotation
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

    def color=(color : Color)
      @dirty = true
      @color = color
    end

    def opacity=(opacity : UInt8)
      @dirty = true
      @color = Color.new(
        r: @color.r,
        g: @color.g,
        b: @color.b,
        a: opacity
      )
    end

    def opacity : UInt8
      @color.a
    end

    def scale=(scale : Tuple(Num, Num))
      @dirty = true
      super.scale = scale
    end

    def scale=(scale : Tuple(Num, Num))
      @dirty = true
      @scale = scale
    end

    def scale_x=(scale_x : Num)
      @dirty = true
      @scale = {scale_x, scale_y}
    end

    def scale_y=(scale_y : Num)
      @dirty = true
      @scale = {scale_x, scale_y}
    end

    def scale=(scale : Num)
      @dirty = true
      @scale = {scale, scale}
    end

    def x=(x : Num)
      @dirty = true
      @x = x
    end

    def y=(y : Num)
      @dirty = true
      @y = y
    end

    @[AlwaysInline]
    def render_x : Num
      global_x - (render_width * origin_x)
    end

    @[AlwaysInline]
    def render_y : Num
      global_y - (render_height * origin_y)
    end

    private def update_lines
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
      space_width = @font_atlas.calculate_width(" ") + @character_spacing * 2

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
      if draw_relative_to_camera?
        _draw(draw)
      else
        draw.with_camera(nil) do
          _draw(draw)
        end
      end
    end

    def _draw(draw : Draw)
      limit = calculate_visible_limit

      if @dirty || limit != @last_visible_limit
        rebuild_vertex_caches(limit)
        @dirty = false
        @last_visible_limit = limit
      end

      z_index = @z_index

      # TODO: implement opacity within here, Font or Draw

      # shadow
      if !@vertices_shadow.empty?
        draw.geometry(@vertices_shadow, get_indices(@vertices_shadow.size), z_index, @font_atlas.texture)
        z_index += 1
      end

      # outline
      if (outline_atlas = @outline_atlas) && !@vertices_outline.empty?
        draw.geometry(@vertices_outline, get_indices(@vertices_outline.size), z_index, outline_atlas.texture)
        z_index += 1
      end

      # Draw the Main Text
      draw.geometry(@vertices_main, get_indices(@vertices_main.size), z_index, @font_atlas.texture)
    end

    private def get_indices(vertex_count : Int) : Array(Int32)
      required_indices = (vertex_count // 4) * 6

      # If we don't have enough, generate only the missing ones
      if @indices.size < required_indices
        current_quads = @indices.size // 6
        target_quads = vertex_count // 4

        (current_quads...target_quads).each do |i|
          v = i * 4
          @indices << v << v + 1 << v + 2
          @indices << v + 2 << v + 3 << v + 0
        end
      end

      # Return a slice of the buffer
      @indices[0...required_indices]
    end

    private def rebuild_vertex_caches(limit : Int32)
      # Shadow - only if used
      if !@shadow.all?(&.zero?)
        offset = {
          @shadow[0] + ( @shadow[0] > 0 ? @outline : -@outline ),
          @shadow[1] + ( @shadow[1] > 0 ? @outline : -@outline )
        }
        @vertices_shadow = generate_vertices(@font_atlas, limit, @shadow_color, offset)
      else
        @vertices_shadow.clear
      end

      # Outline - only if used
      if @outline > 0
        outline_atlas = FontManager.get(@font, font_size, @outline, @weight, @style)
        @vertices_outline = generate_vertices(outline_atlas, limit, @outline_color)
        @outline_atlas = outline_atlas
      else
        @vertices_outline.clear
        @outline_atlas = nil
      end

      # Main
      @vertices_main = generate_vertices(@font_atlas, limit, @color)
    end

    private def generate_vertices(
      font_atlas : Font,
      limit : Int32,
      color : Color,
      offset : {Num, Num} = {0, 0}
    ) : Array(GSDL::Vertex)
      vertices = Array(GSDL::Vertex).new(initial_capacity: limit * 4)
      chars_processed = 0
      off_x, off_y = offset

      # Apply Vertical Alignment
      off_y += case @v_align
        when .center?
          [(self.height - text_height) / 2_f32, 0].max
        when .bottom?
          [self.height - text_height, 0].max
        else 0
      end

      @lines.each_with_index do |line_text, line_index|
        line_limit = [limit - chars_processed, 0].max
        shown_text = line_text[0..[line_limit, line_text.size].min]

        unless shown_text.empty?
          vertices.concat(
            generate_line_vertices(
              font_atlas: font_atlas,
              text: shown_text,
              color: color,
              line_index: line_index,
              offset_x: off_x,
              offset_y: off_y
            )
          )
        end

        chars_processed += line_text.size + 1
        break if chars_processed > limit
      end

      vertices
    end

    private def generate_line_vertices(
      font_atlas : Font,
      text : String,
      color : Color,
      line_index : Int32,
      offset_x : Num,
      offset_y : Num
    ) : Array(GSDL::Vertex)
      line_width = font_atlas.calculate_width(text, @character_spacing)

      # Horizontal Alignment
      offset_x += case @h_align
        when .center?
          (self.width - line_width) / 2
        when .right?
          self.width - line_width
        else 0
      end

      offset_y += line_index * line_height

      # Calculate start positions
      local_start_x = offset_x * scale_x
      local_start_y = offset_y * scale_y

      if @rotation % 360 == 0
        # FAST PATH
        font_atlas.generate_vertices(
          text: text,
          pivot_x: 0,
          pivot_y: 0,
          start_x: render_x + local_start_x,
          start_y: render_y + local_start_y,
          rotation: 0,
          character_spacing: @character_spacing,
          color: color,
          scale_x: scale_x,
          scale_y: scale_y
        )
      else
        # ROTATED PATH
        # The pivot should be the entity's global center (global_x, global_y).
        # We start by positioning text relative to that center using origin offsets.
        base_offset_x = -(self.width * origin_x)
        base_offset_y = -(self.height * origin_y)

        font_atlas.generate_vertices(
          text: text,
          pivot_x: global_x,
          pivot_y: global_y,
          start_x: (base_offset_x + offset_x) * scale_x,
          start_y: (base_offset_y + offset_y) * scale_y,
          rotation: @rotation,
          character_spacing: @character_spacing,
          color: color,
          scale_x: scale_x,
          scale_y: scale_y
        )
      end
    end
  end
end
