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

    @typed_count : UInt8
    @timer : Timer

    def initialize(
      font = Font.default,
      text : String = "",
      x : Num = 0,
      y : Num = 0,
      origin = {0_f32, 0_f32},
      color : Color = Color::White,
      align = Font::Align::Left,
      direction = Font::Direction::LTR,
      wrap_width : Int32? = nil,
      z_index : Int32 = 0,
      @types_per_second : UInt8 = 8_u8,
      @type : Type = Type::Word,
      @on_type : Callback | Nil = nil,
      @on_complete : Callback | Nil = nil
    )
      # init with empty text space char, as it will get typed out
      # empty space char ensures height gets calculated
      super(
        font: font,
        text: " ",
        x: x,
        y: y,
        origin: origin,
        color: color,
        align: align,
        direction: direction,
        wrap_width: wrap_width,
        z_index: z_index
      )

      @full_text = text
      @typed_count = 1
      @timer = Timer.new(seconds_per_type)
      @complete = false
    end

    private def seconds_per_type : Time::Span
      (1_f32 / @types_per_second).seconds
    end

    def types_per_second=(types_per_second : UInt8)
      @timer = Timer.new(seconds_per_type)
    end

    # restarts the typing animation
    def restart
      @typed_count = 1
      @complete = false

      @timer.restart
    end

    def full_text=(value : String)
      @full_text = value

      # update the underlying Text's display and internals, with empty space
      # empty space char ensures height gets calculated
      super(" ")

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
        # append one char at a time
        self.text = @full_text[0...@typed_count]
      else
        # append next word (including pre whitespace)
        self.text = @full_text.scan(/(\s*\S+)/).compact[0...@typed_count].join("")
      end

      @typed_count += 1

      @on_type.try(&.call)

      # reset timer for the next char
      @timer.restart
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

      if @typed_count < total_types
        type_text
      else
        complete
      end
    end
  end
end
