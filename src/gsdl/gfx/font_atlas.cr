module GSDL
  class FontAtlas
    getter font_size : Float32

    @texture : Texture
    @chars : Pointer(LibSTBTrueType::PackedChar)
    @char_count : Int32 = 95
    @first_char : Int32 = 32
    @ascent : Float32 = 0_f32

    def initialize(font_path : String, font_size : Float32, atlas_size : Int32 = 1024)
      @font_size = font_size

      # 1. Buffer Allocation
      pixels = Bytes.new(atlas_size * atlas_size)

      # 2. Context Initialization
      context = LibSTBTrueType::PackContext.new
      res = LibSTBTrueType.pack_begin(
        pointerof(context),
        pixels.to_unsafe,
        atlas_size,
        atlas_size,
        0, # stride (0 = width)
        1, # padding
        nil # alloc_context
      )
      raise "Could not initialize STB font packer" unless res == 1

      # 3. Metadata Preparation
      @chars = Pointer(LibSTBTrueType::PackedChar).malloc(@char_count)

      # 4. Range Packing
      unless File.exists?(font_path)
        raise "Font file not found: #{font_path}"
      end

      font_data = File.read(font_path).to_slice

      res = LibSTBTrueType.pack_font_range(
        pointerof(context),
        font_data.to_unsafe,
        0, # font_index
        font_size,
        @first_char,
        @char_count,
        @chars
      )
      raise "Could not pack font range" unless res == 1

      # 5. Finalization
      LibSTBTrueType.pack_end(pointerof(context))

      # 6. Move to GPU
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

      # 7. Get ascent data
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

    def calculate_width(text : String, character_spacing : Num = 0) : Float32
      total_width = 0_f32

      text.each_char do |char|
        glyph_idx = char.ord - @first_char
        next if glyph_idx < 0 || glyph_idx >= @char_count

        # We only care about the advance, not the visual width (x1-x0)
        # because the advance includes the whitespace/spacing.
        total_width += @chars[glyph_idx].xadvance + character_spacing
      end

      total_width - character_spacing
    end

    def draw_text(
      text : String,
      x : Num,
      y : Num,
      character_spacing : Num = 0,
      color : Color = Color::White,
      scale_x : Num = 1,
      scale_y : Num = 1,
      z_index : Int32 = 0
    )
      current_x = x.to_f32
      baseline_y = y + @ascent * scale_y

      text.each_char do |char|
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

        w = src.w * scale_x
        h = src.h * scale_y
        x = current_x + glyph.xoff * scale_x
        y = baseline_y + glyph.yoff * scale_y

        # Destination rect with offsets applied
        dest = FRect.new(
          x: x,
          y: y,
          w: w,
          h: h
        )

        # Render glyph using GSDL::Draw batching
        Game.draw.texture(
          texture: @texture,
          source_rect: src,
          dest_rect: dest,
          # NOTE: do not use tint here, use `color` to apply full color and alpha
          color: color,
          z_index: z_index
        )

        # Advance horizontal position
        current_x += glyph.xadvance * scale_x + character_spacing * scale_x
      end
    end

    def destroy
      @texture.destroy
    end
  end
end
