module GSDL
  class RichTextTyped < RichText
    alias Callback = Proc(Nil)

    enum Type
      Char
      Word
    end

    getter types_per_second : UInt8
    getter type : Type
    getter? complete : Bool
    getter on_complete : Proc(Nil) | Nil

    @timer : Timer

    def initialize(
      font = Font.default,
      text : String = "",
      x : Num = 0,
      y : Num = 0,
      origin = {0_f32, 0_f32},
      color : Color = Color::White,
      align = Font::Align::Left,
      wrap_width : Int32 = 0,
      z_index : Int32 = 0,
      @types_per_second : UInt8 = 20_u8,
      @type : Type = Type::Char,
      @on_type : Callback | Nil = nil,
      @on_complete : Callback | Nil = nil
    )
      super(
        font: font,
        text: text,
        x: x,
        y: y,
        origin: origin,
        color: color,
        align: align,
        wrap_width: wrap_width,
        visible_characters: 0, # Start hidden
        z_index: z_index
      )

      @timer = Timer.new(seconds_per_type)
      @complete = false
    end

    private def seconds_per_type : Time::Span
      (1_f32 / @types_per_second).seconds
    end

    def types_per_second=(types_per_second : UInt8)
      @types_per_second = types_per_second
      @timer = Timer.new(seconds_per_type)
    end

    def restart
      self.visible_characters = 0
      @complete = false
      @timer.restart
    end

    def complete
      self.visible_characters = total_characters
      @complete = true
      @timer.stop
      @on_complete.try(&.call)
    end

    private def plain_text : String
      @segments.map(&.text).join("")
    end

    def update(dt : Float32)
      return if complete?

      @timer.start unless @timer.started?

      return unless @timer.done?

      if visible_characters < total_characters
        if type.char?
          self.visible_characters += 1
        else
          # Find number of characters to next word
          current_plain = plain_text
          remaining = current_plain[visible_characters..-1]
          
          # Match optional whitespace followed by non-whitespace
          if match = remaining.match(/(\s*\S+)/)
            self.visible_characters += match[0].size
          else
            self.visible_characters = total_characters
          end
        end

        @on_type.try(&.call)
        @timer.restart
      else
        complete
      end
    end
  end
end
