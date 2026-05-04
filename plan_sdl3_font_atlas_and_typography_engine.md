This specification provides everything a developer needs to implement a high-performance font rendering system using Crystal, SDL3, and `stb_truetype`.

---

## **Feature: SDL3 Font Atlas & Typography Engine**

### **Overview**

The goal is to create a `FontAtlas` class that pre-renders a range of font characters into a single GPU texture (an "atlas"). This allows for drawing text by simply copying sub-sections of that texture to the screen, which is significantly faster than rendering individual glyphs on the fly.

### **1. The 5-Step Packing Flow**

This flow uses the `stb_truetype` C library to generate the pixel data and glyph metadata.

1. **Buffer Allocation:** Create a `Bytes` slice of $1024 \times 1024$ (or $512 \times 512$ for pixel fonts) to act as the raw alpha-channel pixel buffer.
2. **Context Initialization:** Call `LibSTBTrueType.pack_begin`. This prepares the C-side `PackContext` to begin fitting rectangles into your buffer.
3. **Metadata Preparation:** Allocate a `Slice(LibSTBTrueType::PackedChar)` with 95 elements (to cover ASCII 32–126).
4. **Range Packing:** Call `LibSTBTrueType.pack_font_range`. This function takes the raw `.ttf` file data and:
   - Renders the glyphs into your `Bytes` buffer.
   - Populates your `PackedChar` slice with coordinates and offsets for every character.
5. **Finalization:** Call `LibSTBTrueType.pack_end` to clean up the C-side packing nodes.

---

### **2. SDL3 Texture Integration**

Once the `Bytes` buffer is full of pixel data, it must be moved to the GPU.

- **Pixel Format:** Use `SDL_PIXELFORMAT_R8`. This format treats each byte as a single Red channel, which we will treat as Alpha.
- **Texture Creation:** Create the texture with `SDL_TEXTUREACCESS_STATIC`.
- **Update:** Use `SDL_UpdateTexture` to upload the `Bytes` slice to the `SDL_Texture`.
- **Alpha Blending:** **CRITICAL.** You must call `SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND)`. Without this, the font background will be opaque.
- **Scaling:** For pixel fonts, set `SDL_SetTextureScaleMode(texture, SDL_SCALEMODE_NEAREST)`.

---

### **3. The Glyph Metadata (PackedChar)**

The `stbtt_packedchar` (aliased as `PackedChar`) contains the math needed to position text correctly.

**FieldPurposex0, y0, x1, y1**The pixel coordinates of the glyph within the $1024 \times 1024$ atlas.**xoff, yoff**The "Bearing." How many pixels to shift the drawing start point relative to the cursor. `yoff` is usually negative to pull the character up from the baseline.**xadvance**How many pixels to move the "cursor" horizontally after drawing this character.

---

### **4. Implementation Requirements**

#### **Class:** `GSDL::FontAtlas`

- **Constructor:** Takes `font_path : String` and `font_size : Float32`. It performs the 5-step packing and texture upload.
- **Mapping:** Implements a private helper to map a `Char` to its index in the metadata slice (`char.ord - 32`).
- **Destructor:** Must call `SDL_DestroyTexture` to prevent memory leaks.

#### **Method:** `draw_text(renderer, text, x, y, color)`

This method loops through the string and renders each character:

1. **Coloration:** Call `SDL_SetTextureColorMod` and `SDL_SetTextureAlphaMod` using the provided `SDL_Color`.
2. **Source Rect:** The `x0, y0, x1, y1` from `PackedChar` define the `SDL_FRect` source.
3. **Destination Rect:**
   - `dest_x = current_x + glyph.xoff`
   - `dest_y = current_y + glyph.yoff`
   - `dest_w = glyph.x1 - glyph.x0`
   - `dest_h = glyph.y1 - glyph.y0`
4. **Render:** Call `SDL_RenderTexture`.
5. **Advance:** Update `current_x += glyph.xadvance`.

---

### **Success Criteria**

- **Baseline Alignment:** Text like "jumping" must have the 'j', 'u', and 'g' aligned correctly on their respective baselines/descenders.
- **Performance:** Drawing a long paragraph should result in only one texture bind and multiple calls to `SDL_RenderTexture`.
- **Cleanup:** Closing the application must not leave any `SDL_Texture` pointers dangling in VRAM.