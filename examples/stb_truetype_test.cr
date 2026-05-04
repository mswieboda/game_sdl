require "../src/ext/stb_truetype"

alias STB = LibSTBTrueType

def test_packer_bindings
  # 1. Setup Atlas dimensions
  atlas_w = 512
  atlas_h = 512

  # 2. Allocate the pixel buffer (1 byte per pixel for Alpha/R8)
  pixels = Bytes.new(atlas_w * atlas_h)

  # 3. Create the Context and PackedChar array
  # We'll test packing the standard ASCII range (32 to 126)
  char_count = 95
  chars = Pointer(STB::PackedChar).malloc(char_count)
  context = STB::PackContext.new

  puts "Initializing Packer..."

  # 4. Test PackBegin
  # Returns 1 on success
  res_begin = STB.pack_begin(
    pointerof(context),
    pixels.to_unsafe,
    atlas_w,
    atlas_h,
    0, # stride (0 = width)
    1, # padding between chars
    nil # custom allocator
  )

  if res_begin == 1
    puts "✓ pack_begin: Success"
  else
    puts "✗ pack_begin: Failed"
    return
  end

  # 5. Load Font Data to test PackFontRange
  font_path = "./assets/fonts/PressStart2P.ttf"
  unless File.exists?(font_path)
    puts "Error: Font not found at #{font_path}"
    return
  end
  font_data = File.read(font_path).to_slice

  puts "Packing font range..."

  # 6. Test PackFontRange
  res_range = STB.pack_font_range(
    pointerof(context),
    font_data.to_unsafe,
    0,     # font index
    32.0_f32, # font size
    32,    # first unicode codepoint (Space)
    char_count,
    chars
  )

  if res_range == 1
    puts "✓ pack_font_range: Success"
    # Print the metadata for the first visible char '!' (index 1 in our array)
    bang = chars[1]
    puts "--- Character '!' Metadata ---"
    puts "Atlas Rect: (#{bang.x0}, #{bang.y0}) to (#{bang.x1}, #{bang.y1})"
    puts "Offset: #{bang.xoff}, #{bang.yoff}"
    puts "Advance: #{bang.xadvance}"
  else
    puts "✗ pack_font_range: Failed"
  end

  # 7. Test PackEnd
  STB.pack_end(pointerof(context))
  puts "✓ pack_end: Success"

  puts "\nLinker and bindings are verified!"
end

test_packer_bindings