module GSDL
  # TODO: Move this to the sdl3 bindings library
  SDL_PIXELFORMAT_R8 = 0x11210101_u32

  class FontAtlas
    @texture : Texture
    @chars : Pointer(LibSTBTrueType::PackedChar)
    @font_size : Float32
    @char_count : Int32 = 95
    @first_char : Int32 = 32

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

      # Move to GPU
      # We use R8 (1-byte per pixel) for the atlas
      @texture = Texture.new(
        width: atlas_size,
        height: atlas_size,
        format: LibSDL3::PixelFormat.new(SDL_PIXELFORMAT_R8.to_i32),
        access: TextureAccess::Static
      )
      
      # Upload pixel data
      # pitch is atlas_size (1 byte per pixel)
      @texture.update(nil, pixels.to_unsafe.as(Void*), atlas_size)
      
      # Alpha Blending is critical for font backgrounds
      @texture.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
      
      # Default to NEAREST for crisp pixel fonts as requested
      @texture.scale_mode = LibSDL3::ScaleMode::Nearest
    end

    def draw_text(text : String, x : Num, y : Num, color : Color = Color::WHITE, z_index : Int32 = 0)
      current_x = x.to_f32
      current_y = y.to_f32

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

        # Destination rect with offsets applied
        dest = FRect.new(
          x: current_x + glyph.xoff,
          y: current_y + glyph.yoff,
          w: src.w,
          h: src.h
        )

        # Render glyph using GSDL::Draw batching
        Game.draw.texture(
          texture: @texture,
          source_rect: src,
          dest_rect: dest,
          tint: color,
          z_index: z_index
        )

        # Advance horizontal position
        current_x += glyph.xadvance
      end
    end

    def destroy
      @texture.destroy
    end
  end
end
