module GSDL
  # A mixin to add 3/4 oblique perspective (depth/height) support to an Entity.
  # This module adds a `z` property that is automatically mapped to `render_offset_y`.
  module Oblique
    property z : Float32 = 0_f32
    property oblique_factor : Float32 = 0.5_f32

    # This should be called in the entity's update method to sync the visual offset.
    def update_oblique
      if self.responds_to?(:render_offset_y=)
        self.render_offset_y = -(z * oblique_factor)
      end
    end
  end
end
