require "./text_box"

module GSDL
  class TextInput < TextBox
    property active : Bool = false
    property max_length : Int32? = nil
    property cursor_position : Int32 = 0
    property cursor_visible : Bool = true
    property cursor_blink_rate : Float32 = 0.5_f32

    property background_color : Color = Color::White
    property border_color : Color = Color::Black
    property border_radius : Num = 0
    property border_width : Num = 1

    delegate text, to: @text

    @blink_timer : Float32 = 0_f32

    def initialize(
      font = Font.default,
      text : String = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = 200,
      height : Int32? = 40,
      padding = TextBox::Padding,
      align = Font::Align::Left,
      x : Num = 0_f32,
      y : Num = 0_f32,
      color = Color::Black,
      @background_color : Color = Color::White,
      @border_color : Color = Color::Black,
      @border_radius : Num = 0,
      @border_width : Num = 1,
      z_index : Int32 = 900,
      @active : Bool = false,
      @max_length : Int32? = nil
    )
      super(
        font: font,
        text: text,
        origin: origin,
        scale: scale,
        width: width,
        height: height,
        padding: padding,
        align: align,
        x: x,
        y: y,
        color: color,
        z_index: z_index
      )
      @cursor_position = text.size
    end

    def update(dt : Float32)
      super(dt)

      if active
        @blink_timer += dt
        if @blink_timer >= cursor_blink_rate
          @blink_timer -= cursor_blink_rate
          @cursor_visible = !@cursor_visible
        end

        handle_input
      else
        @cursor_visible = false
      end
    end

    private def handle_input
      # Handle backspace
      if Keys.just_pressed?(Keys::Backspace) && @cursor_position > 0
        new_text = text[0...@cursor_position - 1] + text[@cursor_position..]
        self.text = new_text
        @cursor_position -= 1
        @cursor_visible = true
        @blink_timer = 0_f32
      end

      # Handle delete
      if Keys.just_pressed?(Keys::Delete) && @cursor_position < text.size
        new_text = text[0...@cursor_position] + text[@cursor_position + 1..]
        self.text = new_text
        @cursor_visible = true
        @blink_timer = 0_f32
      end

      # Handle cursor movement
      if Keys.just_pressed?(Keys::Left) && @cursor_position > 0
        @cursor_position -= 1
        @cursor_visible = true
        @blink_timer = 0_f32
      end

      if Keys.just_pressed?(Keys::Right) && @cursor_position < text.size
        @cursor_position += 1
        @cursor_visible = true
        @blink_timer = 0_f32
      end

      # Handle text input
      new_chars = Input.text_input_this_frame
      if !new_chars.empty?
        if max = max_length
          remaining = max - text.size
          new_chars = new_chars[0...remaining] if new_chars.size > remaining
        end

        unless new_chars.empty?
          new_text = text[0...@cursor_position] + new_chars + text[@cursor_position..]
          self.text = new_text
          @cursor_position += new_chars.size
          @cursor_visible = true
          @blink_timer = 0_f32
        end
      end
    end

    def draw_background(draw : Draw)
      return if background_color.a == 0 && (border_color.a == 0 || border_width <= 0)

      box = Box.new(
        x: x,
        y: y,
        origin: origin,
        scale: scale,
        width: width,
        height: height,
        color: background_color,
        border_radius: border_radius,
        border_thickness: border_width,
        border_color: border_color,
        z_index: z_index
      )
      box.draw(draw)
    end

    def draw_border(draw : Draw)
      # Handled by draw_background to avoid double Box creation
    end

    def draw(draw : Draw)
      super(draw)

      if active && cursor_visible
        # Calculate cursor X position
        before_cursor = text[0...@cursor_position]
        font = @text.font
        offset_x, _ = font.text_size(before_cursor)

        cursor_x = @text.draw_x + (offset_x * @text.scale_x)
        cursor_y_top = @text.draw_y
        cursor_y_bottom = @text.draw_y + @text.draw_height

        draw.color = @text.color
        draw.line(cursor_x, cursor_y_top, cursor_x, cursor_y_bottom, z_index: z_index + 1)
      end
    end
  end
end
