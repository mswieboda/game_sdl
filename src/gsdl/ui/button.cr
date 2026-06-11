require "./container"
require "./text"

module GSDL
  module UI
    class Button < Container
      property on_click : Proc(Nil)? = nil
      property on_hover : Proc(Bool, Nil)? = nil

      property default_background_color : Color
      property hover_background_color : Color
      property default_text_color : Color
      property hover_text_color : Color

      @label : Text
      getter label : Text

      # Track internal hovered state to avoid firing on_hover repeatedly with the same value
      @was_hovered : Bool = false

      def initialize(
        text : String = "",
        @width : Int32 = FillParent,
        @height : Int32 = FillParent,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::Center,
        h_align : HorizontalAlign = HorizontalAlign::Center,
        font_size : Num = 16,
        default_background_color : Color | String = "#2e2e38",
        hover_background_color : Color | String = "#4f46e5",
        default_text_color : Color | String = "#f4f4f5",
        hover_text_color : Color | String = "#f4f4f5",
        padding : Spacing = Spacing.new(all: 0),
        margin : Spacing = Spacing.new(all: 0),
        @flex : UInt8 = 1_u8,
        @on_click : Proc(Nil)? = nil
      )
        @default_background_color = default_background_color.is_a?(String) ? Color.parse(default_background_color) : default_background_color
        @hover_background_color = hover_background_color.is_a?(String) ? Color.parse(hover_background_color) : hover_background_color
        @default_text_color = default_text_color.is_a?(String) ? Color.parse(default_text_color) : default_text_color
        @hover_text_color = hover_text_color.is_a?(String) ? Color.parse(hover_text_color) : hover_text_color

        @background_color = @default_background_color
        @swallows_events = true

        # Create and add the text label
        @label = Text.new(
          text: text,
          font_size: font_size,
          color: @default_text_color,
          width: FillParent,
          height: FillParent,
          h_align: h_align,
          v_align: VerticalAlign::Center,
        )

        self.padding = padding
        self.margin = margin
        self.hover_cursor = GSDL::SystemCursor::Hand
        add_child(@label)
      end

      def initialize(
        text : String = "",
        width : Int32 = FillParent,
        height : Int32 = FillParent,
        x : Int32 = 0,
        y : Int32 = 0,
        anchor : Anchor = Anchor::Center,
        h_align : HorizontalAlign = HorizontalAlign::Center,
        font_size : Num = 16,
        default_background_color : Color | String = "#2e2e38",
        hover_background_color : Color | String = "#4f46e5",
        default_text_color : Color | String = "#f4f4f5",
        hover_text_color : Color | String = "#f4f4f5",
        padding : Spacing = Spacing.new(all: 0),
        margin : Spacing = Spacing.new(all: 0),
        flex : UInt8 = 1_u8,
        &block : ->
      )
        initialize(
          text: text,
          width: width,
          height: height,
          x: x,
          y: y,
          anchor: anchor,
          h_align: h_align,
          font_size: font_size,
          default_background_color: default_background_color,
          hover_background_color: hover_background_color,
          default_text_color: default_text_color,
          hover_text_color: hover_text_color,
          padding: padding,
          margin: margin,
          flex: flex,
          on_click: block
        )
      end

      def text : String
        @label.text
      end

      def text=(val : String)
        @label.text = val
      end

      def hovered=(value : Bool)
        super(value)
        if value
          self.background_color = @hover_background_color
          @label.color = @hover_text_color
        else
          self.background_color = @default_background_color
          @label.color = @default_text_color
        end
        @on_hover.try(&.call(value))
      end

      def update(dt : Float32)
        super(dt)

        if hovered? && GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
          @on_click.try(&.call)
        end
      end
    end
  end
end
