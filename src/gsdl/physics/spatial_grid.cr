module GSDL
  class SpatialGrid
    property cell_size : Int32

    # Map of (cell_x, cell_y) => list of collidables in that cell
    @cells = {} of Tuple(Int32, Int32) => Array(Collidable)

    def initialize(@cell_size = 128)
    end

    # Clear all cells
    def clear
      @cells.clear
    end

    # Insert a collidable into all cells it overlaps
    def insert(collidable : Collidable)
      box = collidable.collision_box

      min_x = (box.left / @cell_size).to_i
      max_x = (box.right / @cell_size).to_i
      min_y = (box.top / @cell_size).to_i
      max_y = (box.bottom / @cell_size).to_i

      (min_x..max_x).each do |cx|
        (min_y..max_y).each do |cy|
          key = {cx, cy}
          @cells[key] ||= [] of Collidable
          @cells[key] << collidable
        end
      end
    end

    # Query for collidables in cells overlapping the given rect
    def query(rect : FRect) : Array(Collidable)
      min_x = (rect.left / @cell_size).to_i
      max_x = (rect.right / @cell_size).to_i
      min_y = (rect.top / @cell_size).to_i
      max_y = (rect.bottom / @cell_size).to_i

      # Use a temporary Set or unique array to avoid returning the same object multiple times
      # if it spans multiple cells.
      results = [] of Collidable

      (min_x..max_x).each do |cx|
        (min_y..max_y).each do |cy|
          if cell = @cells[{cx, cy}]?
            results.concat(cell)
          end
        end
      end

      # Narrow phase candidates must be unique
      results.uniq!
      results
    end
  end
end
