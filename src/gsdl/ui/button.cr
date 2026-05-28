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
          on_click: block
        )
      end

      def text : String
        @label.text
      end

      def text=(val : String)
        @label.text = val
      end

      def update(dt : Float32)
        super(dt)

        # Determine if mouse is currently over this button, respecting z-ordering & hit-testing
        hovered = false
        if root = root_canvas
          curr = root.find_element_at(GSDL::Mouse.x, GSDL::Mouse.y)
          while curr
            if curr == self
              hovered = true
              break
            end
            curr = curr.parent
          end
        end

        # If hover state changed, trigger the callback
        if hovered != @was_hovered
          @was_hovered = hovered
          @on_hover.try(&.call(hovered))
        end

        if hovered
          self.background_color = @hover_background_color
          @label.color = @hover_text_color

          if GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
            @on_click.try(&.call)
          end
        else
          self.background_color = @default_background_color
          @label.color = @default_text_color
        end
      end
    end
  end
end
