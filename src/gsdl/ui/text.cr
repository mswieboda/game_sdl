require "./text_base"

module GSDL
  class Text < TextBase
    def initialize(
      font = Font.default,
      text : String = "",
      x : Num = 0,
      y : Num = 0,
      origin : Tuple(Float32, Float32) = {0_f32, 0_f32},
      scale : Tuple(Num, Num) = {1_f32, 1_f32},
      color = Color::White,
      align = Font::Align::Left,
      direction = Font::Direction::LTR,
      wrap_width : Int32? = nil,
      z_index : Int32 = 0
    )
      super(
        font: font,
        text: text,
        x: x,
        y: y,
        origin: origin,
        scale: scale,
        color: color,
        align: align,
        direction: direction,
        wrap_width: wrap_width,
        z_index: z_index
      )
    end

    def initialize(text_sdl : SDL3::TTF::Text, text : String = "")
      super(text_sdl, text)
    end

    def to_sdl : SDL3::TTF::Text
      @text_sdl
    end

    def draw(draw : Draw)
      return if @text.empty?

      old_scale_x = draw.current_scale_x
      old_scale_y = draw.current_scale_y

      if draw_relative_to_camera?
        draw.scale = Game.camera.zoom
      else
        draw.scale = 1.0_f32
      end

      draw.text(self)

      draw.scale = {old_scale_x, old_scale_y}
    end

    # NOTE: shouldn't be used outside of Draw class, but Draw needs it public
    #   to access the `@text_sdl` internally here
    def _draw(x : Float32, y : Float32)
      if scale_x == 1_f32 && scale_y == 1_f32
        @text_sdl.draw(x, y)
      else
        renderer = TextBase.renderer
        old_scale = renderer.scale
        renderer.scale = {scale_x.to_f32, scale_y.to_f32}

        # We must divide our coordinates by the scale
        # because the renderer's scale multiplies them
        @text_sdl.draw(x / scale_x.to_f32, y / scale_y.to_f32)

        renderer.scale = old_scale
      end
    end
  end
end
