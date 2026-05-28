module GSDL
  class TextBox
    include Centerable
    include Tweenable

    Padding = 16

    getter width : Int32
    getter height : Int32
    getter padding_x : Int32
    getter padding_y : Int32
    getter tweens : Array(Tween) = [] of Tween

    @text : GSDL::Text
    @x : Num = 0_f32
    @y : Num = 0_f32
    @origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    @scale : Tuple(Num, Num) = {1_f32, 1_f32}

    # Explicitly store whether width/height were set manually
    @width_fixed : Bool = false
    @height_fixed : Bool = false

    @z_index : Int32 = 900
    property? draw_relative_to_camera : Bool = false

    delegate z_index, to: @text

    def initialize(
      font : Symbol | FontOld = FontManager.default,
      font_size : Num = FontManager.default_size,
      text : String | GSDL::Text = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = nil,
      height : Int32? = nil,
      padding : Int32? = nil,
      padding_x : Int32? = nil,
      padding_y : Int32? = nil,
      align = FontOld::Align::Left,
      x : Num = 0_f32,
      y : Num = 0_f32,
      color = ColorScheme.get(:ui_text),
      @z_index : Int32 = 900,
      @draw_relative_to_camera : Bool = false
    )
      @padding_x = padding_x || padding || Padding
      @padding_y = padding_y || padding || Padding

      if text.is_a?(String)
        h_align = case align
        when FontOld::Align::Center
          HorizontalAlign::Center
        when FontOld::Align::Right
          HorizontalAlign::Right
        else
          HorizontalAlign::Left
        end

        font_name = font.is_a?(FontOld) ? FontManager.default : font
        resolved_size = font.is_a?(FontOld) ? font.size : font_size

        @text = Text.new(
          font: font_name,
          font_size: resolved_size,
          text: text,
          h_align: h_align,
          v_align: height ? VerticalAlign::Center : VerticalAlign::Top,
          color: color,
          width: width ? width - @padding_x * 2 : nil,
          height: height ? height - @padding_y * 2 : nil,
          z_index: z_index
        )
      else
        @text = text
        # Override properties to match the box if they were provided (or rely on the custom text's own layout)
        if t = @text
          if t.is_a?(Text)
            t.width = width - @padding_x * 2 if width
            t.height = height - @padding_y * 2 if height
            t.v_align = VerticalAlign::Center if height
          elsif t.is_a?(TextOld)
            t.wrap_width = width - @padding_x * 2 if width
          end
          t.z_index = z_index
        end
      end

      if t = @text
        if t.is_a?(TextOld)
          t.wrap_whitespace_visible = true
        end
      end

      @x = x
      @y = y
      @origin = origin
      @scale = scale

      if w = width
        @width = w
        @width_fixed = true
      else
        @width = (text_width + @padding_x * 2).to_i
      end

      if h = height
        @height = h
        @height_fixed = true
      else
        @height = (text_height + @padding_y * 2).to_i
      end

      update_text_position
    end

    private def update_text_position
      # Formula derived to keep text padded within box regardless of origin:
      # text_x = x + padding * scale_x * (1 - 2 * origin_x)
      @text.x = @x + @padding_x * scale_x * (1.0_f32 - 2.0_f32 * origin_x)
      @text.y = @y + @padding_y * scale_y * (1.0_f32 - 2.0_f32 * origin_y)
      @text.origin = @origin
      @text.scale = @scale
      @text.z_index = @z_index
      if (t = @text).is_a?(Text)
        t.draw_relative_to_camera = self.draw_relative_to_camera?
      elsif t.is_a?(TextOld)
        t.draw_relative_to_camera = self.draw_relative_to_camera?
      end
    end

    def x=(x : Num)
      @x = x
      update_text_position
    end

    def y=(y : Num)
      @y = y
      update_text_position
    end

    def z_index=(z_index : Int32)
      @z_index = z_index
      @text.z_index = z_index
    end

    def origin=(origin : Tuple(Float32, Float32))
      @origin = origin
      update_text_position
    end

    def origin_x=(origin_x : Float32)
      self.origin = {origin_x, origin_y}
    end

    def origin_y=(origin_y : Float32)
      self.origin = {origin_x, origin_y}
    end

    def scale=(scale : Tuple(Num, Num))
      @scale = scale
      update_text_position
    end

    def scale_x=(scale_x : Num)
      self.scale = {scale_x, scale_y}
    end

    def scale_y=(scale_y : Num)
      self.scale = {scale_x, scale_y}
    end

    def scale=(scale : Num)
      self.scale = {scale, scale}
    end

    def text : String
      if (t = @text).is_a?(Text)
        t.text
      elsif t.is_a?(TextOld)
        t.text
      else
        ""
      end
    end

    def text=(text : String)
      if (t = @text).is_a?(Text)
        t.text = text
      elsif t.is_a?(TextOld)
        t.text = text
      end
      on_content_changed
    end

    def color : Color
      if (t = @text).is_a?(Text)
        t.color
      elsif t.is_a?(TextOld)
        t.color
      else
        ColorScheme.get(:ui_text)
      end
    end

    def color=(value : Color)
      if (t = @text).is_a?(Text)
        t.color = value
      elsif t.is_a?(TextOld)
        t.color = value
      end
    end

    def padding=(val : Int32)
      @padding_x = val
      @padding_y = val
      on_content_changed
    end

    def padding_x=(val : Int32)
      @padding_x = val
      on_content_changed
    end

    def padding_y=(val : Int32)
      @padding_y = val
      on_content_changed
    end

    def padding
      @padding_x
    end

    def x : Num; @x; end
    def y : Num; @y; end
    def global_x : Num; @x; end
    def global_y : Num; @y; end
    def z_index : Int32; @z_index; end
    def scale : Tuple(Num, Num); @scale; end
    def origin : Tuple(Float32, Float32); @origin; end

    def origin_x : Float32; origin[0]; end
    def origin_y : Float32; origin[1]; end
    def scale_x : Num; scale[0]; end
    def scale_y : Num; scale[1]; end

    def render_width : Num; width * scale_x; end
    def render_height : Num; height * scale_y; end

    def render_x : Num
      global_x - (render_width * origin_x)
    end

    def render_y : Num
      global_y - (render_height * origin_y)
    end

    # Helpers for screen-space interaction (Mouse/Input)
    def screen_x : Num
      draw_relative_to_camera? ? (render_x - Game.camera.x) * Game.camera.zoom : render_x
    end

    def screen_y : Num
      draw_relative_to_camera? ? (render_y - Game.camera.y) * Game.camera.zoom : render_y
    end

    def screen_width : Num
      draw_relative_to_camera? ? render_width * Game.camera.zoom : render_width
    end

    def screen_height : Num
      draw_relative_to_camera? ? render_height * Game.camera.zoom : render_height
    end

    private def on_content_changed
      unless @width_fixed
        @width = (text_width + @padding_x * 2).to_i
      end
      unless @height_fixed
        @height = (text_height + @padding_y * 2).to_i
      end
      update_text_position
    end

    def update(dt : Float32)
      update_tweens(dt)

      # Track text dimensions to detect changes (like in TextTyped)
      old_w = text_width
      old_h = text_height

      @text.update(dt)

      # If text changed size, we need to update our box dimensions and text position
      if text_width != old_w || text_height != old_h
        on_content_changed
      end
    end

    private def text_width : Num
      if (t = @text).is_a?(Text)
        t.width
      elsif t.is_a?(TextOld)
        t.width
      else
        0
      end
    end

    private def text_height : Num
      if (t = @text).is_a?(Text)
        t.height
      elsif t.is_a?(TextOld)
        t.height
      else
        0
      end
    end

    def draw_background(draw : Draw)
    end

    def draw_border(draw : Draw)
    end

    def draw(draw : Draw)
      draw_background(draw)
      draw_border(draw)

      if self.text.includes?("automatically wrapped") || self.text.includes?("OK!")
        puts "DEBUG TextBox text: #{self.text.inspect}"
        puts "  x: #{x}, y: #{y}, width: #{width}, height: #{height}"
        puts "  @text x: #{@text.x}, y: #{@text.y}"
        puts "  self.z_index: #{self.z_index}, @text.z_index: #{@text.z_index}"
        if (t = @text).is_a?(Text)
          puts "  @text: width: #{t.width}, height: #{t.height}"
          puts "  @text: value: #{t.text.inspect}"
        elsif (t = @text).is_a?(TextOld)
          puts "  @text: width: #{t.width}, height: #{t.height}"
        end
      end

      @text.draw(draw)
    end
  end
end
