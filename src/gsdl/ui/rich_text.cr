module GSDL
  class RichText < TextBase
    record RichTextSegment, text : String, color : Color, style : Font::Style
    alias WordInfo = NamedTuple(text: String, color: Color, style: Font::Style, x: Int32, y: Int32, w: Int32, h: Int32)

    @baked_texture : Texture?
    @segments = Array(RichTextSegment).new
    @width : Int32 = 0
    @height : Int32 = 0
    @wrap_width : Int32 = 0
    @visible_characters : Int32 = -1

    def initialize(
      font = Font.default,
      text : String = "",
      x : Num = 0,
      y : Num = 0,
      origin : Tuple(Float32, Float32) = {0_f32, 0_f32},
      scale : Tuple(Num, Num) = {1_f32, 1_f32},
      color : Color = Color::White,
      align : Font::Align = Font::Align::Left,
      wrap_width : Int32 = 0,
      @visible_characters : Int32 = -1,
      @z_index : Int32 = 0
    )
      super(
        font: font,
        text: "",
        x: x,
        y: y,
        origin: origin,
        scale: scale,
        color: color,
        align: align,
        wrap_width: wrap_width,
        z_index: z_index
      )
      @wrap_width = wrap_width
      self.text = text
    end

    def visible_characters=(val : Int32)
      @visible_characters = val
      bake_texture
    end

    def visible_characters : Int32
      @visible_characters
    end

    # Returns the total number of characters (excluding tags)
    def total_characters : Int32
      @segments.sum(&.text.size)
    end

    def text=(text : String)
      @text = text
      parse_segments
      bake_texture
    end

    def wrap_width=(val : Int32)
      @wrap_width = val
      bake_texture
    end

    def width : Int32
      @width
    end

    def height : Int32
      @height
    end

    private def on_content_changed
    end

    private def parse_segments
      @segments.clear
      current_color = self.color
      current_style = Font::Style::Normal

      tag_regex = /<((\/?[bc])|(\/?i)|(c:[^>]+))>/

      last_pos = 0
      @text.scan(tag_regex) do |match|
        pre_text = @text[last_pos...match.begin(0)]
        if !pre_text.empty?
          @segments << RichTextSegment.new(pre_text, current_color, current_style)
        end

        tag_content = match[1]
        case tag_content
        when "b"  then current_style |= Font::Style::Bold
        when "/b" then current_style &= ~Font::Style::Bold
        when "i"  then current_style |= Font::Style::Italic
        when "/i" then current_style &= ~Font::Style::Italic
        when "/c" then current_color = self.color
        else
          if tag_content.starts_with?("c:")
            color_val = tag_content[2..-1]
            current_color = parse_color(color_val)
          end
        end

        last_pos = match.end(0)
      end

      post_text = @text[last_pos..-1]
      if !post_text.empty?
        @segments << RichTextSegment.new(post_text, current_color, current_style)
      end
    end

    private def parse_color(val : String) : Color
      if val.starts_with?("#")
        Color.from_hex(val)
      elsif val.includes?(",")
        parts = val.split(',').map(&.strip.to_i)
        if parts.size == 3
          Color.new(parts[0], parts[1], parts[2])
        elsif parts.size == 4
          Color.new(parts[0], parts[1], parts[2], parts[3])
        else
          self.color
        end
      else
        Color.from_name(val)
      end
    rescue
      self.color
    end

    private def bake_texture
      @baked_texture.try &.destroy
      return if @segments.empty?

      # 1. First Pass: Calculate Layout & Group by Lines
      # Each word has {text, color, style, x, y, w, h}
      lines = [] of Array(WordInfo)
      current_line = [] of WordInfo

      cursor_x = 0
      cursor_y = 0
      max_w = 0
      line_h = font.line_skip > 0 ? font.line_skip : font.height

      @segments.each do |seg|
        # Split by spaces and newlines, but keep them to preserve spacing
        words = seg.text.split(/([ \n\t]+)/)
        words.each do |word|
          next if word.empty?

          if word == "\n"
            lines << current_line
            current_line = [] of WordInfo
            cursor_x = 0
            cursor_y += line_h
            next
          end

          font.style = seg.style
          w, h = font.text_size(word)

          # Wrap if necessary
          if @wrap_width > 0 && cursor_x + w > @wrap_width && !word.strip.empty?
            lines << current_line
            current_line = [] of WordInfo
            cursor_x = 0
            cursor_y += line_h

            # If the word itself is wider than wrap_width, it will just overflow
            # unless we implement character-level wrapping, which we'll skip for now.
          end

          current_line << {text: word, color: seg.color, style: seg.style, x: cursor_x, y: cursor_y, w: w, h: h}
          cursor_x += w
          max_w = Math.max(max_w, cursor_x)
        end
      end
      lines << current_line unless current_line.empty?

      @width = @wrap_width > 0 ? @wrap_width : max_w
      @height = cursor_y + line_h

      return if @width <= 0 || @height <= 0

      # 2. Second Pass: Apply Alignment Offsets
      target_align = font.align
      layout_info = [] of WordInfo

      lines.each do |line|
        next if line.empty?

        # Calculate trailing whitespace width to ignore it for alignment
        line_w = line.last[:x] + line.last[:w]
        trailing_ws = 0
        line.reverse_each do |w_info|
          if w_info[:text].strip.empty?
            trailing_ws += w_info[:w]
          else
            break
          end
        end
        visual_line_w = line_w - trailing_ws

        offset_x = 0
        if target_align == Font::Align::Center
          offset_x = (@width - visual_line_w) // 2
        elsif target_align == Font::Align::Right
          offset_x = @width - visual_line_w
        end

        # Don't allow negative offset (pushing off left edge)
        offset_x = Math.max(0, offset_x)

        line.each do |w_info|
          # Create a new tuple with the adjusted X
          layout_info << {
            text: w_info[:text],
            color: w_info[:color],
            style: w_info[:style],
            x: w_info[:x] + offset_x,
            y: w_info[:y],
            w: w_info[:w],
            h: w_info[:h]
          }
        end
      end

      # 3. Create and Bake
      @baked_texture = Texture.new(@width, @height, access: TextureAccess::Target)
      @baked_texture.not_nil!.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND

      draw = Game.draw
      # Ensure internal segments are left-aligned so our manual offsets are exact
      old_align = font.align
      font.align = Font::Align::Left

      draw.with_target(@baked_texture) do
        draw.color = Color.new(0, 0, 0, 0)
        draw.to_sdl.clear

        remaining_chars = @visible_characters
        show_all = @visible_characters < 0

        layout_info.each do |info|
          break if !show_all && remaining_chars <= 0

          text_to_draw = info[:text]
          if !show_all && text_to_draw.size > remaining_chars
            text_to_draw = text_to_draw[0...remaining_chars]
            remaining_chars = 0
          elsif !show_all
            remaining_chars -= text_to_draw.size
          end

          next if text_to_draw.empty?

          font.style = info[:style]
          temp_text = font.create_text(draw.text_engine, text_to_draw)
          temp_text.color = info[:color]
          temp_text._draw(info[:x].to_f32, info[:y].to_f32)
          temp_text.destroy
        end
      end

      font.style = Font::Style::Normal
      font.align = old_align
    end

    def draw(draw : Draw)
      return unless tex = @baked_texture

      draw.texture(
        tex,
        dest_rect: FRect.new(x: draw_x, y: draw_y, w: draw_width, h: draw_height),
        z_index: z_index
      )
    end

    def _draw(x : Float32, y : Float32)
      return unless tex = @baked_texture

      draw = Game.draw
      draw.to_sdl.render_texture(
        tex.to_sdl,
        nil,
        SDL3::FRect.new(x, y, @width.to_f32, @height.to_f32)
      )
    end

    def destroy
      super
      @baked_texture.try &.destroy
    end
  end
end
