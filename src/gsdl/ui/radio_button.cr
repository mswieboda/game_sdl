require "./container"
require "./text"

module GSDL
  module UI
    class RadioButton < Container
      property? checked : Bool = false
      property group : Symbol
      property on_select : Proc(Nil)? = nil
      property custom_indicator : Proc(Draw, RadioButton, Rect, Bool, Nil)? = nil

      property default_background_color : Color
      property hover_background_color : Color
      property default_text_color : Color
      property hover_text_color : Color

      property radius : Int32
      property inner_radius : Int32

      @label : Text
      getter label : Text

      def initialize(
        text : String = "",
        @group : Symbol = :default,
        @checked : Bool = false,
        @width : Int32 = FitContent,
        @height : Int32 = FitContent,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::Center,
        font_size : Num = 16,
        default_background_color : Color | String = ColorScheme.get(:ui_radio_bg, Color.parse("#1e1e24")),
        hover_background_color : Color | String = ColorScheme.get(:ui_radio_hover_bg, Color.parse("#2e2e38")),
        default_text_color : Color | String = ColorScheme.get(:ui_radio_text, ColorScheme.get(:ui_text, Color.parse("#f4f4f5"))),
        hover_text_color : Color | String = ColorScheme.get(:ui_radio_hover_text, ColorScheme.get(:main, Color.parse("#7c3aed"))),
        @on_select : Proc(Nil)? = nil,
        @padding = Spacing.new(all: 0),
        @margin = Spacing.new(all: 0),
        @flex : UInt8 = 0_u8,
        radius : Int32? = nil,
        inner_radius : Int32? = nil,
        label_offset_x : Int32? = nil,
      )
        @default_background_color = default_background_color.is_a?(String) ? Color.parse(default_background_color) : default_background_color
        @hover_background_color = hover_background_color.is_a?(String) ? Color.parse(hover_background_color) : hover_background_color
        @default_text_color = default_text_color.is_a?(String) ? Color.parse(default_text_color) : default_text_color
        @hover_text_color = hover_text_color.is_a?(String) ? Color.parse(hover_text_color) : hover_text_color

        @background_color = Color::Transparent
        @swallows_events = true

        @radius = radius || (font_size.to_f32 * 1.25).round.to_i32
        @inner_radius = inner_radius || (@radius * 0.5).round.to_i32
        offset_x = label_offset_x || (@radius * 2 + 12)

        @label = Text.new(
          text: text,
          font_size: font_size,
          color: @default_text_color,
          x: offset_x,
          y: 0,
          width: @width == FitContent ? FitContent : FillParent,
          height: @height == FitContent ? FitContent : FillParent,
          h_align: HorizontalAlign::Left,
          v_align: VerticalAlign::Center,
        )

        self.hover_cursor = GSDL::SystemCursor::Hand
        add_child(@label)
      end

      def checked=(val : Bool)
        @checked = val
      end

      def select_this_radio
        return if checked?
        @checked = true
        @on_select.try(&.call)

        if root = root_canvas
          deselect_others_in_group(root)
        end
      end

      private def deselect_others_in_group(element : Element)
        if element.is_a?(RadioButton) && element != self && element.group == self.group
          element.checked = false
        elsif element.is_a?(Container)
          element.children.each do |child|
            deselect_others_in_group(child)
          end
        end
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
          select_this_radio
        end
      end

      def layout!
        super
        @label.y = (content_height - @label.height) // 2
      end

      def draw(draw : Draw)
        super(draw)

        # Dynamically clamp draw_radius to (content_height - 4) // 2 to fit perfectly unclipped inside the container
        draw_radius = [radius, (content_height - 4) // 2].min
        draw_radius = [4, draw_radius].max # Ensure it remains visible

        center_x = content_x + 4 + draw_radius
        center_y = content_y + content_height // 2

        rect = Rect.new(content_x + 4, center_y - draw_radius, draw_radius * 2, draw_radius * 2)

        if cb = @custom_indicator
          cb.call(draw, self, rect, checked?)
        else
          bg_color = hovered? ? @hover_background_color : @default_background_color
          border_color = hovered? ? @hover_text_color : @default_text_color

          # 1. Draw outer circle as a filled circle of border_color to create a solid, gap-free outline
          Circle.new(
            x: center_x,
            y: center_y,
            origin: {0.5_f32, 0.5_f32},
            radius: draw_radius,
            color: border_color,
            z_index: effective_z_index,
            draw_mode: Shape::DrawMode::Fill
          ).draw(draw)

          # 2. Draw inner background circle filled with bg_color, inset by 4 logical pixels (2 visual pixels)
          Circle.new(
            x: center_x,
            y: center_y,
            origin: {0.5_f32, 0.5_f32},
            radius: [2, draw_radius - 4].max,
            color: bg_color,
            z_index: effective_z_index,
            draw_mode: Shape::DrawMode::Fill
          ).draw(draw)

          # 3. Draw selection indicator circle if checked
          if checked?
            # Scale the selection indicator inner radius proportionally
            draw_inner_radius = (draw_radius * inner_radius) // radius
            draw_inner_radius = [2, [draw_inner_radius, draw_radius - 4].min].max

            Circle.new(
              x: center_x,
              y: center_y,
              origin: {0.5_f32, 0.5_f32},
              radius: draw_inner_radius,
              color: @hover_text_color,
              z_index: effective_z_index,
              draw_mode: Shape::DrawMode::Fill
            ).draw(draw)
          end
        end
      end

      def height : Int32
        case @height
        when FitContent
          label_h = @children.empty? ? 0 : @children.max_of { |c| (c.y + c.footprint_height).as(Int32) }
          Math.max(label_h, @radius * 2 + 4)
        else
          super
        end
      end
    end
  end
end
