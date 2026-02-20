require "./text_base"

module GSDL
  class Text < TextBase
    def draw(draw : Draw)
      return if @text.empty?

      draw.text(self)
    end

    # NOTE: shouldn't be used outside of Draw class, but Draw needs it public
    #   to access the `@text_sdl` internally here
    def _draw
      if scale_x == 1_f32 && scale_y == 1_f32
        @text_sdl.draw(draw_x.to_f32, draw_y.to_f32)
      else
        renderer = TextBase.renderer
        old_scale = renderer.scale
        renderer.scale = {scale_x.to_f32, scale_y.to_f32}

        # We must divide our coordinates by the scale
        # because the renderer's scale multiplies them
        @text_sdl.draw(draw_x.to_f32 / scale_x.to_f32, draw_y.to_f32 / scale_y.to_f32)

        renderer.scale = old_scale
      end
    end
  end
end
