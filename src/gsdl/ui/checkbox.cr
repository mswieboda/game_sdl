require "./container"
require "./text"

module GSDL
  module UI
    class Checkbox < Container
      property? checked : Bool = false
      property on_toggle : Proc(Bool, Nil)? = nil
      property custom_indicator : Proc(Draw, Checkbox, Rect, Bool, Nil)? = nil

      property default_background_color : Color
      property hover_background_color : Color
      property default_text_color : Color
      property hover_text_color : Color

      property box_size : Int32
      property inner_size : Int32

      @label : Text
      getter label : Text

      @was_hovered : Bool = false

      def initialize(
        text : String = "",
        @checked : Bool = false,
        @width : Int32 = FillParent,
        @height : Int32 = 28,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::Center,
        font_size : Num = 16,
        default_background_color : Color | String = ColorScheme.get(:ui_checkbox_bg, Color.parse("#1e1e24")),
        hover_background_color : Color | String = ColorScheme.get(:ui_checkbox_hover_bg, Color.parse("#2e2e38")),
        default_text_color : Color | String = ColorScheme.get(:ui_checkbox_text, ColorScheme.get(:ui_text, Color.parse("#f4f4f5"))),
        hover_text_color : Color | String = ColorScheme.get(:ui_checkbox_hover_text, ColorScheme.get(:main, Color.parse("#7c3aed"))),
        @on_toggle : Proc(Bool, Nil)? = nil,
        @padding = Spacing.new(all: 0),
        @margin = Spacing.new(all: 0),
        @flex : UInt8 = 1_u8,
        @box_size : Int32 = 18,
        @inner_size : Int32 = 10,
        label_offset_x : Int32 = 30,
      )
        @default_background_color = default_background_color.is_a?(String) ? Color.parse(default_background_color) : default_background_color
        @hover_background_color = hover_background_color.is_a?(String) ? Color.parse(hover_background_color) : hover_background_color
        @default_text_color = default_text_color.is_a?(String) ? Color.parse(default_text_color) : default_text_color
        @hover_text_color = hover_text_color.is_a?(String) ? Color.parse(hover_text_color) : hover_text_color

        @background_color = Color::Transparent
        @swallows_events = true

        @label = Text.new(
          text: text,
          font_size: font_size,
          color: @default_text_color,
          x: label_offset_x,
          y: 0,
          width: FillParent,
          height: FillParent,
          h_align: HorizontalAlign::Left,
          v_align: VerticalAlign::Center,
        )

        self.hover_cursor = GSDL::SystemCursor::Hand
        add_child(@label)
      end

      def hovered=(value : Bool)
        super(value)
        if value
          @label.color = @hover_text_color
        else
          @label.color = @default_text_color
        end
      end

      def update(dt : Float32)
        super(dt)

        if hovered? && GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
          self.checked = !self.checked?
          @on_toggle.try(&.call(self.checked?))
        end
      end

      def draw(draw : Draw)
        super(draw)

        # Dynamically clamp draw_box_size to content_height - 4 to fit perfectly unclipped inside the container
        draw_box_size = [box_size, content_height - 4].min
        draw_box_size = [8, draw_box_size].max # Ensure it remains visible

        box_x = content_x + 4
        box_y = content_y + (content_height - draw_box_size) // 2

        box_rect = Rect.new(box_x, box_y, draw_box_size, draw_box_size)

        if cb = @custom_indicator
          cb.call(draw, self, box_rect, checked?)
        else
          bg_color = hovered? ? @hover_background_color : @default_background_color
          draw.rect_fill(box_rect, bg_color, effective_z_index)

          border_color = hovered? ? @hover_text_color : @default_text_color
          draw.rect_outline(box_rect, border_color, effective_z_index)

          if checked?
            # Scale the selection indicator box proportionally
            draw_inner_size = (draw_box_size * inner_size) // box_size
            draw_inner_size = [4, [draw_inner_size, draw_box_size - 4].min].max

            inner_x = box_x + (draw_box_size - draw_inner_size) // 2
            inner_y = box_y + (draw_box_size - draw_inner_size) // 2
            inner_rect = Rect.new(inner_x, inner_y, draw_inner_size, draw_inner_size)
            draw.rect_fill(inner_rect, @hover_text_color, effective_z_index)
          end
        end
      end
    end
  end
end
