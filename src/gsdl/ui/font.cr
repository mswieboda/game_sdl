module GSDL
  class GlyphMetric
    property x : Int32
    property y : Int32
    property width : Int32
    property height : Int32
    property bearing_x : Float32
    property bearing_y : Float32
    property advance_x : Float32
    property last_frame_used : UInt64
    property is_active : Bool

    def initialize(
      @x : Int32,
      @y : Int32,
      @width : Int32,
      @height : Int32,
      @bearing_x : Float32,
      @bearing_y : Float32,
      @advance_x : Float32,
      @last_frame_used : UInt64 = 0_u64,
      @is_active : Bool = true
    )
    end
  end

  class Font
    getter name : String
    getter font_size : Num
    getter outline : Int32
    getter texture : Texture

    DefaultFontSize = 16

    @ascent : Float32 = 0_f32
    @oversample : Int32
    @render_font_size : Float32
    @render_outline : Int32

    @font_info : Pointer(LibSTBTrueType::FontInfo)
    @font_scale : Float32
    @texture_width : Int32 = 1024
    @texture_height : Int32 = 1024
    @current_shelf_y : Int32 = 0
    @current_shelf_h : Int32 = 0
    @next_slot_x : Int32 = 0
    @glyph_cache = {} of Char => GlyphMetric

    def initialize(
      @name : String,
      data : Bytes,
      size : Num = DefaultFontSize,
      @outline : Int32 = 0,
    )
      @texture_width = 1024
      @texture_height = 1024

      total_scale = calculate_total_scale
      @font_size = size * total_scale
      @oversample = calculate_oversample(@font_size, total_scale)
      @render_font_size = @font_size.to_f32 * @oversample
      @render_outline = @outline * @oversample

      # Initialize STB Font Info (heap-allocated to insulate Font class from struct size variations)
      @font_info = Pointer(LibSTBTrueType::FontInfo).malloc(1)
      LibSTBTrueType.init_font(@font_info, data.to_unsafe, 0)
      @font_scale = LibSTBTrueType.scale_for_pixel_height(@font_info, @render_font_size)

      # Initialize Empty Texture
      @texture = Texture.new(
        width: @texture_width,
        height: @texture_height,
        format: SDL3::PixelFormat::ABGR8888,
        access: TextureAccess::Streaming
      )
      @texture.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
      @texture.scale_mode = LibSDL3::ScaleMode::Nearest

      # Get ascent data
      ascent = 0
      descent = 0
      line_gap = 0
      LibSTBTrueType.get_font_v_metrics(@font_info, pointerof(ascent), pointerof(descent), pointerof(line_gap))
      @ascent = ascent.to_f32 * @font_scale

      # Shelf allocator variables
      @current_shelf_y = 0
      @current_shelf_h = 0
      @next_slot_x = 0

      # Glyph Cache
      @glyph_cache = {} of Char => GlyphMetric
    end

    def begin_frame : Nil
      @glyph_cache.each_value { |metric| metric.is_active = false }
    end

    def touch_glyph(char : Char) : GlyphMetric
      if metric = @glyph_cache[char]?
        metric.is_active = true
        metric.last_frame_used = GSDL::Internal.instance.fps_counter.frame_count
        return metric
      end

      rasterize_glyph(char)
    end

    private def rasterize_glyph(char : Char) : GlyphMetric
      ix0 = 0
      iy0 = 0
      ix1 = 0
      iy1 = 0
      LibSTBTrueType.get_codepoint_bitmap_box(
        @font_info,
        char.ord,
        @font_scale,
        @font_scale,
        pointerof(ix0),
        pointerof(iy0),
        pointerof(ix1),
        pointerof(iy1)
      )

      w = ix1 - ix0
      h = iy1 - iy0

      advance_width = 0
      left_side_bearing = 0
      LibSTBTrueType.get_codepoint_h_metrics(@font_info, char.ord, pointerof(advance_width), pointerof(left_side_bearing))
      advance_x = advance_width.to_f32 * @font_scale

      # Whitespace / empty glyph handling
      if w == 0 || h == 0
        metric = GlyphMetric.new(
          x: 0,
          y: 0,
          width: 0,
          height: 0,
          bearing_x: ix0.to_f32,
          bearing_y: iy0.to_f32,
          advance_x: advance_x,
          last_frame_used: GSDL::Internal.instance.fps_counter.frame_count,
          is_active: true
        )
        @glyph_cache[char] = metric
        return metric
      end

      padding = @render_outline > 0 ? @render_outline * 2 + 2 : 2
      slot_w = w + padding
      slot_h = h + padding
      shelf_h = @render_font_size.ceil.to_i + padding

      # Capacity check and shelf adjustment
      if @next_slot_x + slot_w > @texture_width
        @current_shelf_y += @current_shelf_h > 0 ? @current_shelf_h : shelf_h
        @next_slot_x = 0
        @current_shelf_h = shelf_h
      elsif @current_shelf_h == 0
        @current_shelf_h = shelf_h
      end

      # Eviction hook
      if @current_shelf_y + slot_h > @texture_height
        inactive_chars = [] of Char
        @glyph_cache.each do |k, metric|
          if !metric.is_active && metric.width > 0 && metric.height > 0
            inactive_chars << k
          end
        end

        if inactive_chars.empty?
          raise "Font Atlas Full: No inactive glyphs available to evict!"
        end

        evict_char = inactive_chars.min_by { |c| @glyph_cache[c].last_frame_used }
        evicted_metric = @glyph_cache.delete(evict_char).not_nil!

        slot_x = evicted_metric.x - padding // 2
        slot_y = evicted_metric.y - padding // 2
        x = slot_x + padding // 2
        y = slot_y + padding // 2
      else
        slot_x = @next_slot_x
        slot_y = @current_shelf_y
        x = slot_x + padding // 2
        y = slot_y + padding // 2
        @next_slot_x += slot_w
      end

      # Rasterize
      temp_pixels = Bytes.new(w * h)
      LibSTBTrueType.make_codepoint_bitmap(
        @font_info,
        temp_pixels.to_unsafe,
        w,
        h,
        w,
        @font_scale,
        @font_scale,
        char.ord
      )

      # Build centered + dilated (optional) block
      padded_pixels = Bytes.new(slot_w * slot_h)
      h.times do |row|
        src_offset = row * w
        dest_offset = (row + padding // 2) * slot_w + padding // 2
        padded_pixels[dest_offset, w].copy_from(temp_pixels[src_offset, w])
      end

      final_pixels = if @render_outline > 0
        dilate(padded_pixels, slot_w, slot_h, @render_outline)
      else
        padded_pixels
      end

      # Convert to ABGR8888
      rgba_pixels = Bytes.new(slot_w * slot_h * 4)
      rgba_ptr = rgba_pixels.to_unsafe.as(UInt32*)
      final_pixels.each_with_index do |alpha, i|
        rgba_ptr[i] = (alpha.to_u32 << 24) | 0x00FFFFFF_u32
      end

      # Upload
      rect = LibSDL3::Rect.new(x: slot_x, y: slot_y, w: slot_w, h: slot_h)
      @texture.update(rect, rgba_ptr.as(Void*), slot_w * 4)

      metric = GlyphMetric.new(
        x: x,
        y: y,
        width: w,
        height: h,
        bearing_x: ix0.to_f32,
        bearing_y: iy0.to_f32,
        advance_x: advance_x,
        last_frame_used: GSDL::Internal.instance.fps_counter.frame_count,
        is_active: true
      )
      @glyph_cache[char] = metric
      metric
    end

    def calculate_total_scale : Float32
      window_w = Game.instance.window_width
      window_h = Game.instance.window_height

      scale_x = 1
      scale_y = 1

      if Game.instance.logical_width > 0
        scale_x = window_w.to_f32 / Game.instance.logical_width
      end

      if Game.instance.logical_height > 0
        scale_y = window_h.to_f32 / Game.instance.logical_height
      end

      logical_scale = Math.max(scale_x, scale_y)

      display_id = LibSDL3.get_display_for_window(Game.instance.window)
      dpi_scale = LibSDL3.get_display_content_scale(display_id)

      logical_scale * dpi_scale
    end

    def calculate_oversample(font_size : Num, total_scale : Float32) : Int32
      quality_multiplier = case font_size
      when 0..16
        1.5
      when 17..48
        1.0
      else
        0.5
      end

      (total_scale * quality_multiplier).ceil.to_i.clamp(1, 8)
    end

    private def dilate(original_pixels : Bytes, width : Int32, height : Int32, outline : Int32) : Bytes
      dilated = Bytes.new(width * height)

      height.times do |y|
        width.times do |x|
          if original_pixels[y * width + x] > 0
            dilated[y * width + x] = 255
            next
          end

          found = false
          (-outline..outline).each do |dy|
            ny = y + dy
            next if ny < 0 || ny >= height

            (-outline..outline).each do |dx|
              nx = x + dx
              next if nx < 0 || nx >= width

              if original_pixels[ny * width + nx] > 0
                found = true
                break
              end
            end
            break if found
          end

          dilated[y * width + x] = 255 if found
        end
      end

      dilated
    end

    def calculate_width(text : String, character_spacing : Num = 0) : Float32
      total_width = 0_f32

      text.each_char do |char|
        metric = touch_glyph(char)
        total_width += (metric.advance_x / @oversample) + character_spacing
      end

      total_width - character_spacing
    end

    def draw_text(
      draw : Draw,
      text : String,
      x : Num,
      y : Num,
      character_spacing : Num = 0,
      color : Color = Color::White,
      scale_x : Num = 1,
      scale_y : Num = 1,
      z_index : Int32 = 0
    )
      current_x = x
      current_y = y + @ascent * scale_y

      text.each_char_with_index do |char, i|
        metric = touch_glyph(char)
        next if metric.width == 0 || metric.height == 0

        src = FRect.new(
          x: (metric.x - @render_outline).to_f32,
          y: (metric.y - @render_outline).to_f32,
          w: (metric.width + (@render_outline * 2)).to_f32,
          h: (metric.height + (@render_outline * 2)).to_f32
        )

        w = (src.w / @oversample) * scale_x
        h = (src.h / @oversample) * scale_y

        logical_outline = @render_outline / @oversample

        gx = current_x + ((metric.bearing_x / @oversample) - logical_outline) * scale_x
        gy = current_y + ((metric.bearing_y / @oversample) - logical_outline) * scale_y

        dest = FRect.new(
          x: gx,
          y: gy,
          w: w,
          h: h
        )

        draw.texture(
          texture: @texture,
          source_rect: src,
          dest_rect: dest,
          color: color,
          z_index: z_index
        )

        current_x += ((metric.advance_x / @oversample) + character_spacing) * scale_x
      end
    end

    def generate_vertices(
      text : String,
      pivot_x : Num,
      pivot_y : Num,
      start_x : Num,
      start_y : Num,
      rotation : Num,
      character_spacing : Num = 0,
      color : Color = Color::White,
      scale_x : Num = 1,
      scale_y : Num = 1
    ) : Array(Vertex)
      vertices = Array(GSDL::Vertex).new(initial_capacity: text.size * 4)

      fcolor = color.to_fcolor
      is_rotated = rotation % 360 != 0

      cos_theta = 0_f32
      sin_theta = 0_f32

      if is_rotated
        radians = rotation * (Math::PI / 180.0)
        cos_theta = Math.cos(radians).to_f32
        sin_theta = Math.sin(radians).to_f32
      end

      tex_w = @texture.width.to_f32
      tex_h = @texture.height.to_f32

      logical_outline = @render_outline / @oversample

      current_x = start_x
      current_y = start_y + @ascent * scale_y

      text.each_char do |char|
        metric = touch_glyph(char)
        next if metric.width == 0 || metric.height == 0

        u1 = (metric.x - @render_outline) / tex_w
        v1 = (metric.y - @render_outline) / tex_h
        u2 = (metric.x + metric.width + @render_outline) / tex_w
        v2 = (metric.y + metric.height + @render_outline) / tex_h

        gw = ((metric.width + (@render_outline * 2)) / @oversample) * scale_x
        gh = ((metric.height + (@render_outline * 2)) / @oversample) * scale_y

        char_x = current_x + ((metric.bearing_x / @oversample) - logical_outline) * scale_x
        char_y = current_y + ((metric.bearing_y / @oversample) - logical_outline) * scale_y

        corners = [
          {px: char_x, py: char_y, u: u1, v: v1},
          {px: char_x + gw, py: char_y, u: u2, v: v1},
          {px: char_x + gw, py: char_y + gh, u: u2, v: v2},
          {px: char_x, py: char_y + gh, u: u1, v: v2}
        ]

        corners.each do |c|
          if is_rotated
            rx = pivot_x + (c[:px] * cos_theta - c[:py] * sin_theta)
            ry = pivot_y + (c[:px] * sin_theta + c[:py] * cos_theta)
            vertices << Vertex.new(FPoint.new(rx, ry), fcolor, FPoint.new(c[:u], c[:v]))
          else
            vertices << Vertex.new(FPoint.new(c[:px], c[:py]), fcolor, FPoint.new(c[:u], c[:v]))
          end
        end

        current_x += ((metric.advance_x / @oversample) + character_spacing) * scale_x
      end

      vertices
    end

    def destroy
      @texture.destroy
    end
  end
end
