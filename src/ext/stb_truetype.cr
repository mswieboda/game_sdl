{% if flag?(:win32) %}
  # This tells Crystal: "Link this object file specifically on Windows"
  @[Link(ldflags: "#{__DIR__}/stb_truetype_win_x64.obj")]
{% else %}
  @[Link(ldflags: "#{__DIR__}/../../build/stb_truetype.o")]
{% end %}

lib LibSTBTrueType
  # This matches the stbtt_fontinfo struct in C
  struct FontInfo
    userdata : Void*
    data : UInt8*
    fontstart : Int32
    num_glyphs : Int32
    loca : Int32
    head : Int32
    glyf : Int32
    hhea : Int32
    hmtx : Int32
    kern : Int32
    gpos : Int32
    svg : Int32
    index_map : Int32
    index_to_loc_format : Int32
  end

  # This struct holds the output for each character
  struct PackedChar
    x0, y0, x1, y1 : UInt16 # Coordinates in the atlas
    xoff, yoff, xadvance : Float32
    xoff2, yoff2 : Float32
  end

  # Opaque struct used by the packer to track state
  struct PackContext
    user_allocator_context : Void*
    pack_info : Void* # Internal stbtt__pack_info
    width, height : Int32
    stride_in_bytes : Int32
    padding : Int32
    skip_missing : Int32
    h_oversample, v_oversample : UInt32
    pixels : UInt8*
    nodes : Void*
  end

  # Optional: Ranges allow you to pack multiple font sizes or
  # different character sets (ASCII, Emoji, etc.) in one go.
  struct PackRange
    font_size : Float32
    first_unicode_codepoint_in_range : Int32
    array_of_unicode_codepoints : Int32*
    num_chars : Int32
    chardata_for_range : PackedChar*
    h_oversample, v_oversample : UInt8
  end


  # --- Initialization ---
  # Parses the TTF data into the FontInfo struct
  fun init_font = stbtt_InitFont(info : FontInfo*, data : UInt8*, offset : Int32) : Int32

  # --- Global Metrics ---
  # Returns vertical metrics (ascent, descent, linegap) in unscaled coordinates
  fun get_font_v_metrics = stbtt_GetFontVMetrics(info : FontInfo*, ascent : Int32*, descent : Int32*, line_gap : Int32*)

  # Returns the scale factor to convert unscaled coordinates to pixel units
  # fun scale_for_pixel_height = stbtt_GetScaleForPixelHeight(info : FontInfo*, pixels : Float32) : Float32
  fun scale_for_pixel_height = stbtt_ScaleForPixelHeight(info : FontInfo*, pixels : Float32) : Float32

  # --- Glyph Metrics ---
  # Gets horizontal metrics (advance width, left side bearing) for a character
  fun get_codepoint_h_metrics = stbtt_GetCodepointHMetrics(info : FontInfo*, codepoint : Int32, advance_width : Int32*, left_side_bearing : Int32*)

  # Calculates the bounding box of a character's bitmap at a specific scale
  fun get_codepoint_bitmap_box = stbtt_GetCodepointBitmapBox(
    info : FontInfo*, 
    codepoint : Int32, 
    scale_x : Float32, 
    scale_y : Float32, 
    ix0 : Int32*, iy0 : Int32*, ix1 : Int32*, iy1 : Int32*
  )

  # --- Rasterization ---
  # The "Workhorse": Renders the character into a pre-allocated pixel buffer
  fun make_codepoint_bitmap = stbtt_MakeCodepointBitmap(
    info : FontInfo*, 
    output : UInt8*, 
    out_w : Int32, 
    out_h : Int32, 
    out_stride : Int32, 
    scale_x : Float32, 
    scale_y : Float32, 
    codepoint : Int32
  )

  # Initializes the packing process
  fun pack_begin = stbtt_PackBegin(spc : PackContext*, pixels : UInt8*, width : Int32, height : Int32, stride_in_bytes : Int32, padding : Int32, alloc_context : Void*) : Int32

  # Ends the packing process and cleans up internal packing nodes
  fun pack_end = stbtt_PackEnd(spc : PackContext*)

  # The main workhorse: renders a range of characters into the atlas
  fun pack_font_range = stbtt_PackFontRange(spc : PackContext*, fontdata : UInt8*, font_index : Int32, font_size : Float32, first_unicode_char_in_range : Int32, num_chars_in_range : Int32, chardata_for_range : PackedChar*) : Int32

  # Sets the oversampling (for crisper text)
  fun pack_set_oversampling = stbtt_PackSetOversampling(spc : PackContext*, h_oversample : UInt32, v_oversample : UInt32)
end
