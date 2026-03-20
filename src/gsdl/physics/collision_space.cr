require "./collidable"

module GSDL
  class CollisionSpace
    property collidables : Array(GSDL::Collidable) = [] of GSDL::Collidable
    property tile_map : GSDL::TileMap? = nil
    property space_bounds : GSDL::FRect? = nil

    def add(collidable : GSDL::Collidable)
      @collidables << collidable unless @collidables.includes?(collidable)
    end

    def remove(collidable : GSDL::Collidable)
      @collidables.delete(collidable)
    end

    def query(rect : GSDL::FRect) : Array(GSDL::Collidable)
      Performance.instance.increment("query")
      @collidables.select { |c| c.collision_box.overlaps?(rect) }
    end
  end
end
