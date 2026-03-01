module GSDL
  class MessageTyped < Message
    getter typed_text : TextTyped

    def initialize(
      font = Font.default,
      text : String = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = nil,
      height : Int32? = nil,
      padding = TextBox::Padding,
      align = Font::Align::Center,
      x : Num = 0_f32,
      y : Num = 0_f32,
      color = Color::Black,
      border_radius : Num = 0,
      types_per_second : UInt8 = 8_u8,
      type : TextTyped::Type = TextTyped::Type::Word,
      on_type : TextTyped::Callback | Nil = nil,
      on_complete : TextTyped::Callback | Nil = nil,
      z_index : Int32 = 900,
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
        border_radius: border_radius,
        z_index: z_index
      )

      # Replace @text with TextTyped. The box size was already calculated
      # based on the full text by the superclass.
      @text = TextTyped.new(
        font: font,
        text: text,
        origin: origin,
        color: color,
        align: align,
        wrap_width: width ? width - padding * 2 : 0,
        z_index: z_index,
        types_per_second: types_per_second,
        type: type,
        on_type: on_type,
        on_complete: on_complete
      )
      @text.wrap_whitespace_visible = true
      @typed_text = @text.as(TextTyped)

      update_text_position
    end

    def complete
      @typed_text.complete
    end

    def complete?
      @typed_text.complete?
    end

    def restart
      @typed_text.restart
    end
  end
end