require "./box_layout"

module GSDL
  module UI
    class HBox < BoxLayout
      def layout!
        return if @children.empty?

        # PASS 0: Reset dynamic children layout
        @children.each(&.reset_layout!)

        # PASS 1: Measurement
        # Ensure all children measure themselves so their footprints are accurate.
        @children.each(&.layout!)

        # PASS 2: Proportions
        # Now that fixed children know their size, we can calculate the flex-shares
        calculate_flex_sizes(self.width, is_horizontal: true)

        # PASS 3: Sequencing
        current_x = 0
        @children.each do |child|
          child.x = current_x
          child.y = 0
          current_x += child.footprint_width + @spacing
        end

        # PASS 4: Cross-axis alignment (Stretch)
        if stretch?
          parent_inner_height = self.height
          @children.each do |child|
            if !child.height_fixed?
              child.set_layout_height(parent_inner_height - child.margin.vertical)
            end
          end
        end

        @dirty_layout = false
      end
    end
  end
end
