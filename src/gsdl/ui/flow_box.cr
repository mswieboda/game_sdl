require "./container"

module GSDL
  module UI
    enum Orientation
      Horizontal
      Vertical
    end

    class FlowBox < Container
      property orientation : Orientation = Orientation::Horizontal
      property spacing : Int32 = 0
      property line_spacing : Int32 = 0

      def initialize(
        @orientation : Orientation = Orientation::Horizontal,
        @spacing : Int32 = 0,
        @line_spacing : Int32 = 0,
        @width : Int32 = FillParent,
        @height : Int32 = FitContent,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::TopLeft,
        @flex : UInt8 = 0_u8,
        @padding = Spacing.new(all: 0),
        @margin = Spacing.new(all: 0),
        @background_color : Color? = nil
      )
      end

      def layout!
        return if @children.empty?

        # PASS 0: Reset dynamic children layout and coerce FillParent along main-axis to FitContent
        @children.each do |child|
          child.reset_layout!
          if @orientation.horizontal?
            if child.style_width == FillParent
              child.set_layout_width(FitContent)
            end
          else
            if child.style_height == FillParent
              child.set_layout_height(FitContent)
            end
          end
        end

        # PASS 1: Measurement
        # Ensure all children measure themselves so their footprints are accurate.
        @children.each(&.layout!)

        # PASS 2: Positioning
        current_x = 0
        current_y = 0
        max_line_size = 0

        if @orientation.horizontal?
          limit_width = width_fixed? ? self.width : Int32::MAX

          @children.each do |child|
            child_footprint_w = child.footprint_width
            child_footprint_h = child.footprint_height

            if current_x > 0 && current_x + child_footprint_w > limit_width
              current_x = 0
              current_y += max_line_size + @line_spacing
              max_line_size = 0
            end

            child.x = current_x
            child.y = current_y

            current_x += child_footprint_w + @spacing
            max_line_size = Math.max(max_line_size, child_footprint_h)
          end
        else
          limit_height = height_fixed? ? self.height : Int32::MAX

          @children.each do |child|
            child_footprint_w = child.footprint_width
            child_footprint_h = child.footprint_height

            if current_y > 0 && current_y + child_footprint_h > limit_height
              current_y = 0
              current_x += max_line_size + @line_spacing
              max_line_size = 0
            end

            child.x = current_x
            child.y = current_y

            current_y += child_footprint_h + @spacing
            max_line_size = Math.max(max_line_size, child_footprint_w)
          end
        end

        @dirty_layout = false
      end
    end
  end
end
