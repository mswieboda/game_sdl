require "./text_old"

module GSDL
  class RichText < TextOld
    record RichTextSegment, text : String, color : Color, style : Font::Style

    @baked_texture : Texture?
    @segments = Array(RichTextSegment).new

    def initialize(
      font = Font.default,
      text : String = "",
      x : Num = 0,
      y : Num = 0,
      origin : Tuple(Float32, Float32) = {0_f32, 0_f32},
      scale : Tuple(Num, Num) = {1_f32, 1_f32},
      color : Color = ColorScheme.get(:ui_text),
      align : Font::Align = Font::Align::Left,
      wrap_width : Int32 = 0,
      visible_characters : Int32 = -1,
      @z_index : Int32 = 0,
      oversample_ratio : Float32 = TextOld::OversampleRatio,
      draw_relative_to_camera : Bool = true,
    )
      # We don't want the Text constructor to bake anything yet because segments aren't parsed
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
        z_index: z_index,
        oversample_ratio: oversample_ratio,
        visible_characters: visible_characters,
        draw_relative_to_camera: draw_relative_to_camera,
      )
      self.text = text
    end

    # Returns the total number of characters (excluding tags)
    def total_characters : Int32
      @segments.sum(&.text.size)
    end

    def text=(text : String)
      @text = text
      parse_segments
      layout!
      bake!
    end

    def wrap_width=(val : Int32)
      @wrap_width = val
      layout!
      bake!
    end

    def width : Int32
      @logical_width
    end

    def height : Int32
      @logical_height
    end

    private def on_content_changed
    end

    private def parse_segments
      @segments.clear
      current_color = self.color
      current_style = Font::Style::Normal

      tag_regex = /<(\/?b|\/?i|c:[^>]+|\/c)>/

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
          # Color.new(red: parts[0], green: parts[1], blue: parts[2])
          Color.new(red: parts[0], green: parts[1])
        elsif parts.size == 4
          Color.new(red: parts[0], green: parts[1], blue: parts[2], alpha: parts[3])
        else
          self.color
        end
      else
        Color.from_name(val)
      end
    rescue
      self.color
    end

    def layout!
      @layout_info.clear
      @logical_width = 0
      @logical_height = 0
      return if @segments.empty?

      # 1. First Pass: Calculate Layout & Group by Lines (at Logical Scale)
      lines = [] of Array(WordInfo)
      current_line = [] of WordInfo

      cursor_x = 0
      cursor_y = 0
      max_w = 0
      line_h = font.line_skip > 0 ? font.line_skip : font.height

      @segments.each do |seg|
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

          if (ww = @wrap_width) && ww > 0 && cursor_x + w > ww && !word.strip.empty?
            lines << current_line
            current_line = [] of WordInfo
            cursor_x = 0
            cursor_y += line_h
          end

          current_line << WordInfo.new(text: word, x: cursor_x, y: cursor_y, w: w, h: h)
          cursor_x += w
          max_w = Math.max(max_w, cursor_x)
        end
      end
      lines << current_line unless current_line.empty?

      ww = @wrap_width
      @logical_width = (ww && ww > 0) ? ww : max_w
      @logical_height = cursor_y + line_h

      return if @logical_width <= 0 || @logical_height <= 0

      # 2. Second Pass: Apply Alignment Offsets
      target_align = font.align

      lines.each do |line|
        next if line.empty?
        line_w = line.last.x + line.last.w
        trailing_ws = 0
        line.reverse_each do |w_info|
          if w_info.text.strip.empty?
            trailing_ws += w_info.w
          else
            break
          end
        end
        visual_line_w = line_w - trailing_ws

        offset_x = 0
        if target_align == Font::Align::Center
          offset_x = (@logical_width - visual_line_w) // 2
        elsif target_align == Font::Align::Right
          offset_x = @logical_width - visual_line_w
        end
        offset_x = Math.max(0, offset_x)

        line.each do |w_info|
          @layout_info << WordInfo.new(
            text: w_info.text,
            x: w_info.x + offset_x,
            y: w_info.y,
            w: w_info.w,
            h: w_info.h
          )
        end
      end
    end

    def bake!
      @baked_texture.try &.destroy
      @baked_texture = nil
      return if @layout_info.empty?

      # 3. Create and Bake (at Oversampled Scale)
      baked_w = (@logical_width * oversample_ratio).to_i
      baked_h = (@logical_height * oversample_ratio).to_i
      master_surface = Surface.new(width: baked_w, height: baked_h)
      master_surface.fill(Color.new(0, 0, 0, 0)) # Transparent

      old_align = font.align
      font.align = Font::Align::Left
      original_size = font.size
      font.size = original_size * oversample_ratio

      remaining_chars = @visible_characters
      show_all = @visible_characters < 0

      # Since we need segment info (style, color) for baking, we need to map layout_info back or store it.
      # Re-parsing during bake is not ideal. Let's adjust layout_info to include style/color if it's RichText.
      # Actually, let's just use the segment-based bake logic here.
      
      # We need to know which segment each WordInfo came from.
      # Simplified: re-walk segments with the layout positions.
      
      char_count = 0
      seg_idx = 0
      layout_idx = 0
      
      @segments.each do |seg|
        words = seg.text.split(/([ \n\t]+)/)
        words.each do |word|
          next if word.empty?
          if word == "\n"
            next
          end
          
          # This should correspond to @layout_info[layout_idx]
          info = @layout_info[layout_idx]
          layout_idx += 1
          
          break if !show_all && remaining_chars <= 0

          text_to_draw = word
          if !show_all && text_to_draw.size > remaining_chars
            text_to_draw = text_to_draw[0...remaining_chars]
            remaining_chars = 0
          elsif !show_all
            remaining_chars -= text_to_draw.size
          end

          next if text_to_draw.empty?

          font.style = seg.style
          surface = font.render_text_blended(text_to_draw, seg.color)
          
          if surface
            dest_rect = Rect.new(
              x: (info.x.to_f32 * oversample_ratio).to_i,
              y: (info.y.to_f32 * oversample_ratio).to_i,
              w: surface.width,
              h: surface.height
            )
            surface.blit(nil, dest_rect, master_surface)
            surface.destroy
          end
        end
      end

      font.size = original_size
      font.style = Font::Style::Normal
      font.align = old_align

      @baked_texture = Texture.from_surface(master_surface)
      @baked_texture.not_nil!.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
      master_surface.destroy
    end

    def draw(draw : Draw)
      if draw_relative_to_camera?
        perform_draw(draw)
      else
        draw.with_camera(nil) do
          perform_draw(draw)
        end
      end
    end

    private def perform_draw(draw : Draw)
      return unless tex = @baked_texture

      dest_rect = FRect.new(
        x: render_x.to_f32,
        y: render_y.to_f32,
        w: render_width.to_f32,
        h: render_height.to_f32
      )

      tex.alpha_mod = opacity
      draw.texture_rotated(
        texture: tex,
        dest_rect: dest_rect,
        angle: rotation.to_f32,
        center: center_point_from_origin,
        z_index: z_index
      )
      tex.alpha_mod = 255_u8
    end

    def _draw(x : Float32, y : Float32)
      return unless tex = @baked_texture

      draw = Game.draw
      draw.to_sdl.render_texture(
        tex.to_sdl,
        nil,
        SDL3::FRect.new(x, y, render_width.to_f32, render_height.to_f32)
      )
    end

    def destroy
      super
      @baked_texture.try &.destroy
    end
  end
end
