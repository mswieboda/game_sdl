require "./collision_space"

module GSDL
  module SceneCollisions
    getter collision_space : CollisionSpace = CollisionSpace.new

    def refresh_collision_space
      collision_space.refresh_grid
    end

    def add_child(entity : Entity)
      super
      collision_space.add(entity.as(GSDL::Collidable)) if entity.is_a?(GSDL::Collidable)
      entity
    end

    def remove_child(entity : Entity)
      super
      collision_space.remove(entity.as(GSDL::Collidable)) if entity.is_a?(GSDL::Collidable)
      entity
    end
  end
end
