module GSDL
  class TextTyped < Text
    getter full_text : String
    getter chars_per_second : UInt8
    getter? complete : Bool
    getter on_complete : Proc(Nil) | Nil

    @typed_char_count : UInt8
    @timer : Timer

    def initialize(
      font = Font.default,
      text = "",
      x = 0_f32,
      y = 0_f32,
      color = GSDL::Colors::White,
      @chars_per_second : UInt8 = 16_u8,
      @on_complete : Proc(Nil) | Nil = nil
    )
      # init with empty text, as it will be typed
      super(font: font, text: "", x: x, y: y, color: color)

      @full_text = text
      @typed_char_count = 1
      @timer = Timer.new(seconds_per_character)
      @complete = false
    end

    private def seconds_per_character : Time::Span
      (1_f32 / @chars_per_second).seconds
    end

    def chars_per_second=(chars_per_second : UInt8)
      @timer = Timer.new(seconds_per_character)
    end

    # restarts the typing animation
    def restart
      @typed_char_count = 1
      @complete = false

      @timer.restart
    end

    def full_text=(value : String)
      @full_text = value

      # update the underlying Text's display and surface
      super("")

      restart
    end

    def complete
      self.text = @full_text
      @complete = true

      @timer.stop
      @on_complete.try(&.call)
    end

    def update(dt : Float32)
      return if complete?

      @timer.start unless @timer.started?

      return unless @timer.done?

      if @typed_char_count < @full_text.size
        # append one char at a time
        current_display_text = @full_text[0...@typed_char_count]

        # update the underlying Text's display
        self.text = current_display_text

        @typed_char_count += 1

        # reset timer for the next char
        @timer.restart
      else
        complete
      end
    end
  end
end
