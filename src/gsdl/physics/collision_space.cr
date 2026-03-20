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
  end
end
