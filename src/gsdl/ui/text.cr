require "./text_base"

module GSDL
  class Text < TextBase
    @texture : Texture?
    @needs_refresh = true

    def initialize(
      font = Font.default,
      text : String = "",
      x : Num = 0,
      y : Num = 0,
      origin : Tuple(Float32, Float32) = {0_f32, 0_f32},
      scale : Tuple(Num, Num) = {1_f32, 1_f32},
      color = ColorScheme.get(:ui_text),
      align = Font::Align::Left,
      direction = Font::Direction::LTR,
      wrap_width : Int32? = nil,
      z_index : Int32 = 0,
      rotation : Num = 0.0
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
        z_index: z_index,
        rotation: rotation
      )
    end

    def initialize(text_sdl : SDL3::TTF::Text, text : String = "")
      super(text_sdl, text)
    end

    private def on_content_changed
      @needs_refresh = true
    end

    def text=(text : String)
      super(text)
      @needs_refresh = true
    end

    def rotation=(val : Num)
      @rotation = val
    end

    def refresh_texture
      return unless @needs_refresh
      @texture.try(&.destroy)
      @texture = nil

      return if @text.empty?

      w, h = size
      return if w <= 0 || h <= 0

      renderer = TextBase.renderer

      # Create a target texture
      tex = Texture.new(width: w, height: h, access: TextureAccess::Target)
      tex.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND

      # Save current state
      old_target = renderer.render_target
      old_scale = renderer.scale

      # Render text to texture
      renderer.render_target = tex.to_sdl
      renderer.scale = {1_f32, 1_f32}

      # Clear to transparent
      old_color = renderer.draw_color
      renderer.draw_color = {0_u8, 0_u8, 0_u8, 0_u8}
      renderer.clear

      # Draw at (0,0)
      @text_sdl.draw(0_f32, 0_f32)

      # Restore
      renderer.render_target = old_target
      renderer.scale = old_scale
      renderer.draw_color = {old_color.r, old_color.g, old_color.b, old_color.a}

      @texture = tex
      @needs_refresh = false
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

      if rotation != 0
        refresh_texture
        if tex = @texture
          dest_rect = FRect.new(
            x: draw_x.to_f32,
            y: draw_y.to_f32,
            w: draw_width.to_f32,
            h: draw_height.to_f32
          )

          draw.texture_rotated(
            texture: tex,
            dest_rect: dest_rect,
            angle: rotation,
            center: center_point_from_origin,
            z_index: z_index
          )
        end
      else
        draw.text(self)
      end

      draw.scale = {old_scale_x, old_scale_y}
    end

    # NOTE: shouldn't be used outside of Draw class, but Draw needs it public
    #   to access the `@text_sdl` internally here
    def _draw(x : Float32, y : Float32)
      if scale_x == 1_f32 && scale_y == 1_f32
        @text_sdl.draw(x, y)
      else
        renderer = TextBase.renderer
        old_scale_x, old_scale_y = renderer.scale
        renderer.scale = {scale_x.to_f32 * old_scale_x, scale_y.to_f32 * old_scale_y}

        # We must divide our coordinates by the scale
        # because the renderer's scale multiplies them
        @text_sdl.draw(x / scale_x.to_f32, y / scale_y.to_f32)

        renderer.scale = {old_scale_x, old_scale_y}
      end
    end

    def destroy
      super
      @texture.try(&.destroy)
    end
  end
end
