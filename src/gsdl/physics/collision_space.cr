require "./collidable"

module GSDL
  class CollisionSpace
    property collidables : Array(GSDL::Collidable) = [] of GSDL::Collidable
    property tile_map : GSDL::TileMap? = nil
    property space_bounds : GSDL::FRect? = nil

    @grid = SpatialGrid.new
    @last_refresh_frame : UInt64 = 0

    def add(collidable : GSDL::Collidable)
      @collidables << collidable unless @collidables.includes?(collidable)
    end

    def remove(collidable : GSDL::Collidable)
      @collidables.delete(collidable)
    end

    # Refresh the spatial grid if it hasn't been updated this frame
    def refresh_grid
      current_frame = Internal.instance.fps_counter.frame_count
      return if @last_refresh_frame == current_frame

      @grid.clear
      @collidables.each do |c|
        @grid.insert(c)
      end
      @last_refresh_frame = current_frame
    end

    def query(rect : GSDL::FRect) : Array(GSDL::Collidable)
      refresh_grid
      Performance.instance.increment("query")
      @grid.query(rect)
    end
  end
end
