module GSDL
  class FontAtlas
    getter font_size : Num
    getter outline : Int32

    DefaultAtlasSize = 1024
    DefaultFontSize = 16

    @texture : Texture
    @chars : Pointer(LibSTBTrueType::PackedChar)
    @char_count : Int32 = 95
    @first_char : Int32 = 32
    @ascent : Float32 = 0_f32
    @oversample : Int32
    @render_font_size : Float32
    @render_outline : Int32

    getter thickness : Int32 = 0

    def initialize(
      font_path : String,
      font_size : Num = DefaultFontSize,
      atlas_size : Int32 = DefaultAtlasSize,
      @outline : Int32 = 0,
    )
      unless File.exists?(font_path)
        raise "Font file not found: #{font_path}"
      end

      total_scale = calculate_total_scale
      @font_size = font_size * total_scale
      @oversample = calculate_oversample(@font_size, total_scale)
      @render_font_size = font_size.to_f32 * @oversample
      @render_outline = @outline * @oversample

      font_data = File.read(font_path).to_slice
      @chars = Pointer(LibSTBTrueType::PackedChar).malloc(@char_count)

      pixels = Bytes.new(0)
      atlas_size = calculate_initial_size(@char_count, @render_font_size, @render_outline)
      success = false

      pack_context = LibSTBTrueType::PackContext.new

      until success
        # Setup the packing context for current atlas_size
        pixels = Bytes.new(atlas_size * atlas_size)

        res = LibSTBTrueType.pack_begin(
          pointerof(pack_context),
          pixels.to_unsafe,
          atlas_size,
          atlas_size,
          0, # stride (0 = width)
          1, # padding
          nil # alloc_context
        )
        raise "Could not initialize STB font packer" unless res == 1

        # Try to pack the range
        res = LibSTBTrueType.pack_font_range(
          pointerof(pack_context),
          font_data,
          0, # font index
          @render_font_size,
          @first_char,
          @char_count,
          @chars
        )

        if res == 1 # Success!
          success = true

          LibSTBTrueType.pack_end(pointerof(pack_context))
        else
          # Too small! Double the dimensions and wipe the buffer
          atlas_size *= 2
          raise "Font Atlas too large for GPU" if atlas_size > 4096
        end
      end

      # account for outline
      if @outline > 0
        # 1. Create a "fat" version of the 1-byte alpha mask
        pixels = dilate(pixels, atlas_size, atlas_size, @render_outline)
      end

      # Move to GPU
      # We use ABGR8888 (4-byte per pixel) for the atlas
      @texture = Texture.new(
        width: atlas_size,
        height: atlas_size,
        format: SDL3::PixelFormat::ABGR8888,
        access: TextureAccess::Static
      )

      # convert to ABGR8888
      rgba_pixels = Bytes.new(atlas_size * atlas_size * 4)
      rgba_ptr = rgba_pixels.to_unsafe.as(UInt32*)

      # convert 1-byte pixels to 4-byte pixels in ONE pass
      pixels.each_with_index do |alpha, i|
        # pack: alpha (shifted 24 bits) + blue/green/red (0x00FFFFFF)
        # this assumes ABGR8888 on a little-endian system
        rgba_ptr[i] = (alpha.to_u32 << 24) | 0x00FFFFFF_u32
      end

      # upload to texture
      @texture.update(nil, rgba_ptr.as(Void*), atlas_size * 4)
      
      # alpha Blending is critical for font backgrounds
      @texture.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
      
      # default to NEAREST for crisp pixel fonts as requested
      @texture.scale_mode = LibSDL3::ScaleMode::Nearest

      # Get ascent data
      font_info = LibSTBTrueType::FontInfo.new
      LibSTBTrueType.init_font(pointerof(font_info), font_data.to_unsafe, 0)

      scale = LibSTBTrueType.scale_for_pixel_height(pointerof(font_info), font_size)

      # Get vertical metrics
      ascent = 0
      descent = 0
      line_gap = 0

      LibSTBTrueType.get_font_v_metrics(pointerof(font_info), pointerof(ascent), pointerof(descent), pointerof(line_gap))

      # Scale them to pixels
      @ascent = ascent.to_f32 * scale
    end

    def calculate_total_scale : Float32
      # 1. How much is the game stretched logically?
      # Assuming you have access to the window size and logical size
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

      # We care about the larger scale to ensure crispness
      logical_scale = Math.max(scale_x, scale_y)

      # 2. Get the OS/DPI scale (usually 1.0, 1.5, or 2.0)
      display_id = LibSDL3.get_display_for_window(Game.instance.window)
      dpi_scale = LibSDL3.get_display_content_scale(display_id)

      # The total physical-to-logical ratio
      logical_scale * dpi_scale
    end

    def calculate_oversample(font_size : Num, total_scale : Float32) : Int32
      # If we are scaling up 3x, we want at least 3x oversampling.
      # We still apply the "diminishing returns" so big fonts don't explode the atlas.
      quality_multiplier = case font_size
       when 0..16
        # Extra boost for tiny text
        1.5
       when 17..48
        1.0
       else
        # Larger text needs less help
        0.5
       end

      # Resulting oversample ratio
      (total_scale * quality_multiplier).ceil.to_i.clamp(1, 8)
    end

    def calculate_initial_size(char_count : Int32, font_size : Float32, outline : Int32) : Int32
      # Add padding for the outline on all sides of the glyph
      glyph_box = font_size + (outline * 2)
      total_area = char_count * glyph_box * glyph_box

      # Find the side length, then find the next power of 2
      side = Math.sqrt(total_area).ceil.to_i
      power_of_2 = 128
      while power_of_2 < side
        power_of_2 <<= 1
      end

      # Clamp to a reasonable max (like 4096) for GPU limits
      power_of_2.clamp(128, 4096)
    end

    private def dilate(original_pixels : Bytes, width : Int32, height : Int32, thickness : Int32) : Bytes
      dilated = Bytes.new(width * height)

      # For every pixel in the texture
      height.times do |y|
        width.times do |x|
          # If the original pixel is already "on", the dilated one is too
          if original_pixels[y * width + x] > 0
            dilated[y * width + x] = 255
            next
          end

          # Search neighborhood within the thickness radius
          # Using a square bounding box for the search
          found = false
          (-thickness..thickness).each do |dy|
            ny = y + dy
            next if ny < 0 || ny >= height

            (-thickness..thickness).each do |dx|
              nx = x + dx
              next if nx < 0 || nx >= width

              # Circular check: is this pixel within the radius?
              if (dx*dx + dy*dy) <= (thickness * thickness)
                if original_pixels[ny * width + nx] > 0
                  found = true
                  break
                end
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
        glyph_idx = char.ord - @first_char
        next if glyph_idx < 0 || glyph_idx >= @char_count

        # We only care about the advance, not the visual width (x1-x0)
        # because the advance includes the whitespace/spacing.
        total_width += (@chars[glyph_idx].xadvance / @oversample) + character_spacing
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
      # Undo oversample for the ascent to find the correct logical baseline
      current_x = x
      current_y = y + @ascent * scale_y

      text.each_char_with_index do |char, i|
        glyph_idx = char.ord - @first_char
        next if glyph_idx < 0 || glyph_idx >= @char_count

        glyph = @chars[glyph_idx]

        # Source rect in the atlas
        src = FRect.new(
          x: glyph.x0.to_f32,
          y: glyph.y0.to_f32,
          w: (glyph.x1 - glyph.x0).to_f32,
          h: (glyph.y1 - glyph.y0).to_f32
        )

        # Divide physical dimensions and offsets by @oversample to get logical size
        w = (src.w / @oversample) * scale_x
        h = (src.h / @oversample) * scale_y
        gx = current_x + (glyph.xoff / @oversample) * scale_x
        gy = current_y + (glyph.yoff / @oversample) * scale_y

        # Destination rect with offsets applied
        dest = FRect.new(
          x: gx,
          y: gy,
          w: w,
          h: h
        )

        # Render glyph using GSDL::Draw batching
        draw.texture(
          texture: @texture,
          source_rect: src,
          dest_rect: dest,
          # NOTE: do not use tint here, use `color` to apply full color and alpha
          color: color,
          z_index: z_index
        )

        # Advance horizontal position and undo oversample
        current_x += ((glyph.xadvance / @oversample) + character_spacing) * scale_x
      end
    end

    def draw_text_rotated(
      draw : Draw,
      text : String,
      pivot_x : Num,
      pivot_y : Num,
      start_x : Num,
      start_y : Num,
      rotation : Num,
      character_spacing : Num = 0,
      color : Color = Color::White,
      scale_x : Num = 1,
      scale_y : Num = 1,
      z_index : Int32 = 0
    )
      radians = rotation * (Math::PI / 180.0)
      cos_theta = Math.cos(radians)
      sin_theta = Math.sin(radians)

      tex_w = @texture.width.to_f32
      tex_h = @texture.height.to_f32

      # Calculate where the "start" of the text is relative to the pivot
      # This depends on your alignment math passed down from TextBeta
      current_x = start_x
      current_y = start_y + @ascent * scale_y

      text.each_char do |char|
        glyph_idx = char.ord - @first_char
        next if glyph_idx < 0 || glyph_idx >= @char_count

        glyph = @chars[glyph_idx]

        # Normalize atlas coordinates to 0.0-1.0 range
        u1 = glyph.x0 / tex_w
        v1 = glyph.y0 / tex_h
        u2 = glyph.x1 / tex_w
        v2 = glyph.y1 / tex_h

        # Calculate logical dimensions and offsets, undo oversample
        gw = ((glyph.x1 - glyph.x0) / @oversample) * scale_x
        gh = ((glyph.y1 - glyph.y0) / @oversample) * scale_y
        char_x = current_x + ((glyph.xoff / @oversample) * scale_x)
        char_y = current_y + ((glyph.yoff / @oversample) * scale_y)

        # Vertex Rotation Math
        # Define local quad corners relative to current_x/y
        corners = [
          # top left
          {px: char_x, py: char_y, u: u1, v: v1},
          # top right
          {px: char_x + gw, py: char_y, u: u2, v: v1},
          # bottom right
          {px: char_x + gw, py: char_y + gh, u: u2, v: v2},
          # bottom left
          {px: char_x, py: char_y + gh, u: u1, v: v2}
        ]

        # Rotate each corner and create vertex objects
        vertices = corners.map do |p|
          # Rotate
          rx = pivot_x + (p[:px] * cos_theta - p[:py] * sin_theta)
          ry = pivot_y + (p[:px] * sin_theta + p[:py] * cos_theta)

          # Build the Vertex with texture coordinates (texture_point)
          GSDL::Vertex.new(
            x: rx.to_f32,
            y: ry.to_f32,
            color: color,
            texture_point: GSDL::Point.new(p[:u], p[:v])
          )
        end

        # Standard quad indices for two triangles
        indices = [0, 1, 2, 2, 3, 0]

        draw.geometry(
          vertices: vertices,
          indices: indices,
          z_index: z_index,
          texture: @texture # The FontAtlas texture
        )

        # Advance horizontal position and undo oversample
        current_x += ((glyph.xadvance / @oversample) + character_spacing) * scale_x
      end
    end

    def destroy
      @texture.destroy
    end
  end
end
