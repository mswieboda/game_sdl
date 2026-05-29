require "./container"
require "./text"

module GSDL
  module UI
    class Checkbox < Container
      property? checked : Bool = false
      property on_toggle : Proc(Bool, Nil)? = nil

      property default_background_color : Color
      property hover_background_color : Color
      property default_text_color : Color
      property hover_text_color : Color

      @label : Text
      getter label : Text

      @was_hovered : Bool = false

      def initialize(
        text : String = "",
        @checked : Bool = false,
        @width : Int32 = FillParent,
        @height : Int32 = 24,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::Center,
        font_size : Num = 16,
        default_background_color : Color | String = "#1e1e24",
        hover_background_color : Color | String = "#2e2e38",
        default_text_color : Color | String = "#f4f4f5",
        hover_text_color : Color | String = "#7c3aed",
        @on_toggle : Proc(Bool, Nil)? = nil,
        @padding = Spacing.new(all: 0),
        @margin = Spacing.new(all: 0)
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
          x: 24,
          y: 0,
          width: FillParent,
          height: FillParent,
          h_align: HorizontalAlign::Left,
          v_align: VerticalAlign::Center,
        )

        add_child(@label)
      end

      def update(dt : Float32)
        super(dt)

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

        if hovered
          @label.color = @hover_text_color

          if GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
            self.checked = !self.checked?
            @on_toggle.try(&.call(self.checked?))
          end
        else
          @label.color = @default_text_color
        end
      end

      def draw(draw : Draw)
        super(draw)

        box_size = 16
        box_x = content_x
        box_y = content_y + (content_height - box_size) // 2

        box_rect = Rect.new(box_x, box_y, box_size, box_size)

        draw.rect_outline(box_rect, @default_text_color, effective_z_index)

        if checked?
          inner_size = 8
          inner_x = box_x + (box_size - inner_size) // 2
          inner_y = box_y + (box_size - inner_size) // 2
          inner_rect = Rect.new(inner_x, inner_y, inner_size, inner_size)
          draw.rect_fill(inner_rect, @hover_text_color, effective_z_index)
        end
      end
    end
  end
end
