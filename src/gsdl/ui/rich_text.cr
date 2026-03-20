module GSDL
  class RichText < TextBase
    record RichTextSegment, text : String, color : Color, style : Font::Style

    @baked_texture : Texture?
    @segments = Array(RichTextSegment).new
    @width : Int32 = 0
    @height : Int32 = 0
    @wrap_width : Int32 = 0

    def initialize(
      font = Font.default,
      text : String = "",
      x : Num = 0,
      y : Num = 0,
      origin : Tuple(Float32, Float32) = {0_f32, 0_f32},
      scale : Tuple(Num, Num) = {1_f32, 1_f32},
      color : Color = Color::White,
      wrap_width : Int32 = 0,
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
        wrap_width: wrap_width,
        z_index: z_index
      )
      @wrap_width = wrap_width
      self.text = text
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

      # 1. Calculate Layout & Word Wrapping
      layout_info = Array(NamedTuple(text: String, color: Color, style: Font::Style, x: Int32, y: Int32, w: Int32, h: Int32)).new

      cursor_x = 0
      cursor_y = 0
      max_w = 0
      line_h = font.line_skip > 0 ? font.line_skip : font.height

      @segments.each do |seg|
        # Split by spaces and newlines, but keep them
        words = seg.text.split(/([ \n\t]+)/)
        words.each do |word|
          next if word.empty?

          if word == "\n"
            cursor_x = 0
            cursor_y += line_h
            next
          end

          font.style = seg.style
          w, h = font.text_size(word)

          # Wrap if necessary
          if @wrap_width > 0 && cursor_x + w > @wrap_width && !word.strip.empty?
            cursor_x = 0
            cursor_y += line_h
          end

          layout_info << {text: word, color: seg.color, style: seg.style, x: cursor_x, y: cursor_y, w: w, h: h}
          cursor_x += w
          max_w = Math.max(max_w, cursor_x)
        end
      end

      @width = @wrap_width > 0 ? @wrap_width : max_w
      @height = cursor_y + line_h

      return if @width <= 0 || @height <= 0

      @baked_texture = Texture.new(@width, @height, access: TextureAccess::Target)
      @baked_texture.not_nil!.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND

      draw = Game.draw
      # Ensure internal segments are left-aligned
      old_align = font.align
      font.align = Font::Align::Left

      draw.with_target(@baked_texture) do
        draw.color = Color.new(0, 0, 0, 0)
        draw.to_sdl.clear

        layout_info.each do |info|
          font.style = info[:style]
          temp_text = font.create_text(draw.text_engine, info[:text])
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
