require "./container"
require "./text"

module GSDL
  module UI
    class RadioButton < Container
      property? checked : Bool = false
      property group : Symbol
      property on_select : Proc(Nil)? = nil

      property default_text_color : Color
      property hover_text_color : Color

      @label : Text
      getter label : Text

      def initialize(
        text : String = "",
        @group : Symbol = :default,
        @checked : Bool = false,
        @width : Int32 = FillParent,
        @height : Int32 = 24,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::Center,
        font_size : Num = 16,
        default_text_color : Color | String = "#f4f4f5",
        hover_text_color : Color | String = "#7c3aed",
        @on_select : Proc(Nil)? = nil
      )
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
            select_this_radio
          end
        else
          @label.color = @default_text_color
        end
      end

      def draw(draw : Draw)
        super(draw)

        radius = 8
        center_x = content_x + 12
        center_y = content_y + content_height // 2

        Circle.new(
          x: center_x,
          y: center_y,
          origin: {0.5_f32, 0.5_f32},
          radius: radius,
          color: @default_text_color,
          z_index: effective_z_index,
          draw_mode: Shape::DrawMode::Outline
        ).draw(draw)

        if checked?
          inner_radius = 4
          Circle.new(
            x: center_x,
            y: center_y,
            origin: {0.5_f32, 0.5_f32},
            radius: inner_radius,
            color: @hover_text_color,
            z_index: effective_z_index,
            draw_mode: Shape::DrawMode::Fill
          ).draw(draw)
        end
      end
    end
  end
end
