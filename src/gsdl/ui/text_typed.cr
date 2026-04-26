module GSDL
  class TextTyped < Text
    alias Callback = Proc(Nil)

    enum Type
      Char
      Word
    end

    getter full_text : String
    getter types_per_second : UInt8
    getter type : Type
    getter? complete : Bool
    getter on_complete : Proc(Nil) | Nil

    @typed_count : Int32
    @timer : Timer

    def initialize(
      font = Font.default,
      text : String = "",
      x : Num = 0,
      y : Num = 0,
      origin = {0_f32, 0_f32},
      color : Color = ColorScheme.get(:ui_text),
      align = Font::Align::Left,
      wrap_width : Int32? = nil,
      z_index : Int32 = 0,
      @types_per_second : UInt8 = 8_u8,
      @type : Type = Type::Word,
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
        z_index: z_index,
        visible_characters: 0
      )
      @full_text = text
      @typed_count = 0
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

    # restarts the typing animation
    def restart
      @typed_count = 0
      @complete = false
      self.visible_characters = 0

      @timer.restart
    end

    def full_text=(value : String)
      @full_text = value
      self.text = value
      restart
    end

    def total_types
      if type.char?
        @full_text.size
      else
        @full_text.split(/\s+/).size
      end
    end

    def type_text
      if type.char?
        @typed_count += 1
        self.visible_characters = @typed_count
      else
        @typed_count += 1
        # Calculate characters for words
        words = @full_text.scan(/(\s*\S+)/).compact[0...@typed_count]
        self.visible_characters = words.sum(&.[0].size)
      end

      @on_type.try(&.call)

      # reset timer for the next char
      @timer.restart
    end

    def complete
      self.visible_characters = -1
      @complete = true

      @timer.stop
      @on_complete.try(&.call)
    end

    def update(dt : Float32)
      return if complete?

      @timer.start unless @timer.started?

      return unless @timer.done?

      if @typed_count < total_types
        type_text
      else
        complete
      end
    end
  end
end
