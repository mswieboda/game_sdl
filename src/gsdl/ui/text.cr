require "./text_beta"

module GSDL
  alias Text = TextBeta

  class TextOld < Entity
    include Centerable

    OversampleRatio = 8_f32

    record WordInfo, text : String, x : Int32, y : Int32, w : Int32, h : Int32

    property text : String
    property font : Font
    property color : Color
    property align : Font::Align
    property wrap_width : Int32?
    property oversample_ratio : Float32 = OversampleRatio
    property? draw_relative_to_camera : Bool
    property rotation : Num = 0.0
    property wrap_whitespace_visible : Bool
    property visible_characters : Int32
    property opacity : UInt8

    @texture : Texture?
    @layout_info = [] of WordInfo
    @logical_width : Int32 = 0
    @logical_height : Int32 = 0

    def initialize(
      @font = Font.default,
      @text : String = "",
      x : Num = 0,
      y : Num = 0,
      origin : Tuple(Float32, Float32) = {0_f32, 0_f32},
      scale : Tuple(Num, Num) = {1_f32, 1_f32},
      @color = ColorScheme.get(:ui_text),
      @align = Font::Align::Left,
      @wrap_width : Int32? = nil,
      @z_index : Int32 = 0,
      @rotation : Num = 0.0,
      @oversample_ratio : Float32 = OversampleRatio,
      @visible_characters : Int32 = -1,
      @opacity : UInt8 = 255_u8,
      @draw_relative_to_camera : Bool = true,
      @wrap_whitespace_visible : Bool = false,
    )
      @x = x.to_f32
      @y = y.to_f32
      @origin = origin
      @scale = scale

      layout!
      bake!
    end

    def text=(@text : String)
      layout!
      bake!
    end

    def font=(@font : Font)
      layout!
      bake!
    end

    def color=(@color : Color)
      bake!
    end

    def align=(@align : Font::Align)
      layout!
      bake!
    end

    def wrap_width=(@wrap_width : Int32?)
      layout!
      bake!
    end

    def oversample_ratio=(@oversample_ratio : Float32)
      layout!
      bake!
    end

    def visible_characters=(@visible_characters : Int32)
      bake!
    end

    def layout!
      @layout_info.clear
      @logical_width = 0
      @logical_height = 0
      return if @text.empty?

      lines = @text.split("\n")
      
      # Use line_skip if available, otherwise font height
      logical_line_height = @font.line_skip > 0 ? @font.line_skip : @font.height
      
      raw_lines = [] of Array(WordInfo)
      current_y = 0
      max_w = 0

      lines.each do |line|
        if line.empty?
          current_y += logical_line_height
          next
        end

        line_words = [] of WordInfo
        cursor_x = 0

        words = line.split(/([ \t]+)/)
        words.each do |word|
          next if word.empty?
          
          w, h = @font.text_size(word)
          
          if (ww = @wrap_width) && ww > 0 && cursor_x + w > ww && !word.strip.empty?
            raw_lines << line_words
            line_words = [] of WordInfo
            cursor_x = 0
            current_y += logical_line_height
          end

          line_words << WordInfo.new(text: word, x: cursor_x, y: current_y, w: w, h: h)
          cursor_x += w
          max_w = Math.max(max_w, cursor_x)
        end
        raw_lines << line_words unless line_words.empty?
        current_y += logical_line_height
      end

      ww = @wrap_width
      @logical_width = (ww && ww > 0) ? ww : max_w
      @logical_height = current_y

      # Apply alignment
      raw_lines.each do |line_words|
        next if line_words.empty?
        
        line_w = line_words.last.x + line_words.last.w
        # ignore trailing whitespace for alignment
        trailing_ws = 0
        line_words.reverse_each do |w|
          if w.text.strip.empty?
            trailing_ws += w.w
          else
            break
          end
        end
        visual_line_w = line_w - trailing_ws

        offset_x = 0
        case @align
        when Font::Align::Center
          offset_x = (@logical_width - visual_line_w) // 2
        when Font::Align::Right
          offset_x = @logical_width - visual_line_w
        end
        offset_x = Math.max(0, offset_x)

        line_words.each do |w|
          @layout_info << WordInfo.new(
            text: w.text,
            x: w.x + offset_x,
            y: w.y,
            w: w.w,
            h: w.h
          )
        end
      end
    end

    def bake!
      @texture.try(&.destroy)
      @texture = nil

      return if @layout_info.empty?

      original_size = @font.size
      @font.size = original_size * @oversample_ratio
      @font.align = @align

      baked_w = (@logical_width * @oversample_ratio).to_i
      baked_h = (@logical_height * @oversample_ratio).to_i
      
      master_surface = Surface.new(width: baked_w, height: baked_h)
      master_surface.fill(Color.new(0, 0, 0, 0)) # Transparent

      remaining_chars = @visible_characters
      show_all = @visible_characters < 0

      @layout_info.each do |info|
        break if !show_all && remaining_chars <= 0

        text_to_draw = info.text
        if !show_all && text_to_draw.size > remaining_chars
          text_to_draw = text_to_draw[0...remaining_chars]
          remaining_chars = 0
        elsif !show_all
          remaining_chars -= text_to_draw.size
        end

        next if text_to_draw.empty?

        surf = @font.render_text_blended(text_to_draw, @color)
        if surf
          dest_rect = Rect.new(
            x: (info.x * @oversample_ratio).to_i,
            y: (info.y * @oversample_ratio).to_i,
            w: surf.width,
            h: surf.height
          )
          surf.blit(nil, dest_rect, master_surface)
          surf.destroy
        end
      end

      # Restore font size
      @font.size = original_size

      @texture = Texture.from_surface(master_surface)
      @texture.not_nil!.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND
      master_surface.destroy
    end

    def width : Int32
      @logical_width
    end

    def height : Int32
      @logical_height
    end

    def render_width : Num
      width * scale_x
    end

    def render_height : Num
      height * scale_y
    end

    def render_x : Num
      global_x - (render_width * origin_x)
    end

    def render_y : Num
      global_y - (render_height * origin_y)
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
      return unless tex = @texture

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

    def destroy
      @texture.try(&.destroy)
    end

    def cursor_pos(char_index : Int32) : Point
      return Point.new(0, 0) if @layout_info.empty? || char_index <= 0
      
      count = 0
      @layout_info.each do |info|
        if count + info.text.size >= char_index
          # Found the word containing the character
          remaining = char_index - count
          prefix = info.text[0...remaining]
          offset_x, _ = @font.text_size(prefix)
          return Point.new(info.x + offset_x, info.y)
        end
        count += info.text.size
      end
      
      # If index is beyond total text, return end of last word
      last = @layout_info.last
      return Point.new(last.x + last.w, last.y)
    end
  end
end
