require "./container"

module GSDL
  module UI
    abstract class BoxLayout < Container
      property spacing : Int32 = 0
      property? stretch : Bool = true

      def initialize(@width = FillParent, @height = FillParent, @spacing = 0, @stretch = true)
      end

      # Helper to distribute remaining space among flexible children
      protected def calculate_flex_sizes(total_available : Int32, is_horizontal : Bool)
        flex_children = [] of Element
        total_flex = 0_u32
        fixed_sum = 0

        # Account for spacing between children
        spacing_sum = @children.empty? ? 0 : (@children.size - 1) * @spacing

        @children.each do |child|
          if child.flex > 0
            flex_children << child
            total_flex += child.flex
          else
            fixed_sum += is_horizontal ? child.footprint_width : child.footprint_height
          end
        end

        remaining_space = total_available - fixed_sum - spacing_sum

        if total_flex > 0
          # Even if remaining_space is <= 0, we still need to set flexible children
          # to 0 to avoid them taking up their previous/default size.
          safe_remaining = Math.max(0, remaining_space)

          flex_children.each do |child|
            allocated = (safe_remaining * child.flex) // total_flex

            if is_horizontal
              child.set_layout_width(allocated - child.margin.horizontal - child.padding.horizontal)
            else
              child.set_layout_height(allocated - child.margin.vertical - child.padding.vertical)
            end
          end
        end
      end
    end
  end
end
