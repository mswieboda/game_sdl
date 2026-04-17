require "./text_base"

module GSDL
  class TextRotated < TextBase
    @texture : Texture?
    @needs_refresh = true

    def initialize(
      font = Font.default,
      text = "",
      x = 0,
      y = 0,
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      color = ColorScheme.get(:ui_text),
      align = Font::Align::Left,
      direction = Font::Direction::LTR,
      wrap_width : Int32? = nil,
      z_index : Int32 = 0,
      @rotation : Num = 0.0
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
      @needs_refresh = true
    end

    def rotation : Num
      @rotation
    end

    def rotation=(val : Num)
      @rotation = val
    end

    private def on_content_changed
      @needs_refresh = true
    end

    def refresh_texture
      return unless @needs_refresh
      @texture.try(&.destroy)
      @texture = nil

      return if @text.empty?

      w, h = size
      return if w <= 0 || h <= 0

      # TODO: do this from the Draw class eventually, instead of SDL3::Renderer
      renderer = TextBase.renderer

      # Create a target texture
      # We use RGBA8888 for high quality and alpha support
      tex = Texture.new(width: w, height: h, access: TextureAccess::Target)
      tex.blend_mode = LibSDL3::SDL_BLENDMODE_BLEND

      # Save current target and scale
      old_target = renderer.render_target
      old_scale = renderer.scale

      # Render text to texture
      renderer.render_target = tex.to_sdl
      renderer.scale = {1_f32, 1_f32} # Draw text at 1:1 to its cache

      # Clear texture to transparent
      old_color = renderer.draw_color
      renderer.draw_color = {0_u8, 0_u8, 0_u8, 0_u8}
      renderer.clear

      # Draw the TTF_Text at (0,0) on the texture
      @text_sdl.draw(0_f32, 0_f32)

      # Restore renderer state
      renderer.render_target = old_target
      renderer.scale = old_scale
      renderer.draw_color = {old_color.r, old_color.g, old_color.b, old_color.a}

      @texture = tex
      @needs_refresh = false
    end

    def draw(draw : Draw)
      return if @text.empty?
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
    end

    def _draw(x : Float32, y : Float32)
      # In TextRotated, we don't use _draw in the same way because
      # we want to leverage Draw's texture command sorting if possible,
      # but Text commands are handled differently.
      # For now, draw(draw) handles it via draw.texture_rotated.
    end

    def destroy
      super
      @texture.try(&.destroy)
    end
  end
end
