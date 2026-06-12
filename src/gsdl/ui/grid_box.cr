require "./container"

module GSDL
  module UI
    class GridBox < Container
      property columns : Int32 = 3
      property rows : Int32? = nil
      property col_spacing : Int32 = 0
      property row_spacing : Int32 = 0
      property? uniform_cells : Bool = true

      def initialize(
        @columns : Int32 = 3,
        @rows : Int32? = nil,
        @col_spacing : Int32 = 0,
        @row_spacing : Int32 = 0,
        @uniform_cells : Bool = true,
        @width : Int32 = FillParent,
        @height : Int32 = FillParent,
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

        # PASS 0: Reset dynamic children layout
        @children.each(&.reset_layout!)

        # PASS 1: Measurement
        @children.each(&.layout!)

        actual_rows = @rows || ((@children.size + @columns - 1) // @columns)
        return if actual_rows <= 0

        cell_width = 0
        cell_height = 0

        if @uniform_cells
          if width_fixed?
            cell_width = (self.width - (@columns - 1) * @col_spacing) // @columns
          else
            cell_width = @children.max_of(&.footprint_width)
          end
          cell_width = Math.max(1, cell_width)

          if height_fixed?
            cell_height = (self.height - (actual_rows - 1) * @row_spacing) // actual_rows
          else
            cell_height = @children.max_of(&.footprint_height)
          end
          cell_height = Math.max(1, cell_height)

          @children.each_with_index do |child, index|
            col = index % @columns
            row = index // @columns
            next if row >= actual_rows

            if child.style_width <= 0
              child.set_layout_width(cell_width - child.margin.horizontal)
            end
            if child.style_height <= 0
              child.set_layout_height(cell_height - child.margin.vertical)
            end

            child.x = col * (cell_width + @col_spacing)
            child.y = row * (cell_height + @row_spacing)
          end
        else
          # Non-uniform cells
          col_widths = Array(Int32).new(@columns, 0)
          row_heights = Array(Int32).new(actual_rows, 0)

          @children.each_with_index do |child, index|
            col = index % @columns
            row = index // @columns
            next if row >= actual_rows

            col_widths[col] = Math.max(col_widths[col], child.footprint_width)
            row_heights[row] = Math.max(row_heights[row], child.footprint_height)
          end

          col_starts = Array(Int32).new(@columns, 0)
          current_x = 0
          @columns.times do |col|
            col_starts[col] = current_x
            current_x += col_widths[col] + @col_spacing
          end

          row_starts = Array(Int32).new(actual_rows, 0)
          current_y = 0
          actual_rows.times do |row|
            row_starts[row] = current_y
            current_y += row_heights[row] + @row_spacing
          end

          @children.each_with_index do |child, index|
            col = index % @columns
            row = index // @columns
            next if row >= actual_rows

            if child.style_width <= 0
              child.set_layout_width(col_widths[col] - child.margin.horizontal)
            end
            if child.style_height <= 0
              child.set_layout_height(row_heights[row] - child.margin.vertical)
            end

            child.x = col_starts[col]
            child.y = row_starts[row]
          end
        end

        @dirty_layout = false
      end
    end
  end
end
