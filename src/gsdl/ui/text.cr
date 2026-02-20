module GSDL
  class Text
    include Tweenable

    property text
    property x : Num
    property y : Num
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property z_index : Int32 = 0
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    getter tweens : Array(Tween) = [] of Tween

    @@renderer : SDL3::Renderer?

    @text_sdl : SDL3::TTF::Text

    delegate color, to: @text_sdl
    delegate :"color=", to: @text_sdl
    delegate direction, to: @text_sdl
    delegate :"direction=", to: @text_sdl
    delegate text_engine, to: @text_sdl
    delegate :"text_engine=", to: @text_sdl
    delegate font, to: @text_sdl
    delegate :"font=", to: @text_sdl
    delegate width, to: @text_sdl
    delegate wrap_whitespace_visible?, to: @text_sdl
    delegate :"wrap_whitespace_visible=", to: @text_sdl
    delegate wrap_width, to: @text_sdl
    delegate :"wrap_width=", to: @text_sdl
    delegate size, to: @text_sdl

    def initialize(
      font = Font.default,
      @text = "",
      @x = 0,
      @y = 0,
      @origin = {0_f32, 0_f32},
      color = Color::White,
      align = Font::Align::Left,
      direction = SDL3::TTF::Direction::LTR,
      wrap_width : Int32? = nil,
      @z_index : Int32 = 0
    )
      if font.align != align
        font = font.copy
        font.align = align
      end

      # NOTE: needs to be Text.renderer in case of child classes
      text_engine = Text.renderer.create_text_engine
      @text_sdl = text_engine.create_text(font, @text)

      @text_sdl.color = color
      @text_sdl.direction = direction
      @text_sdl.font = font

      # TODO: maybe make a constructor param
      @text_sdl.wrap_whitespace_visible = false

      if ww = wrap_width
        @text_sdl.wrap_width = ww
      end
    end

    def self.draw=(draw : Draw)
      @@renderer = draw.to_sdl
    end

    def self.renderer : SDL3::Renderer
      if renderer = @@renderer
        renderer
      else
        raise "GSDL::Text.renderer not set, should be set via GSDL::Game.init"
      end
    end

    def text=(text : String)
      # saved internally for parent classes since there is
      # no SDL3::TTF::Text#text to get text
      @text = text
      @text_sdl.text = text
    end

    def height
      had_newlines = @text.includes?("\n")
      text_size_wrapped = font.text_size_wrapped(@text, width)

      text_size_wrapped[1] - (had_newlines ? font.size.to_i : 0)
    end

    def origin_x : Float32
      origin[0]
    end

    def origin_y : Float32
      origin[1]
    end

    def draw_width : Num
      width * scale_x
    end

    def draw_height : Num
      height * scale_y
    end

    def draw_x : Num
      x - (draw_width * origin_x)
    end

    def draw_y : Num
      y - (draw_height * origin_y)
    end

    def scale_x : Num
      scale[0]
    end

    def scale_y : Num
      scale[1]
    end

    def scale_x=(scale_x : Num)
      self.scale = {scale_x, scale_y}
    end

    def scale_y=(scale_y : Num)
      self.scale = {scale_x, scale_y}
    end

    def scale=(scale : Num)
      self.scale = {scale, scale}
    end

    def tint : Color?
      @text_sdl.color
    end

    def tint=(tint : Color?)
      @text_sdl.color = tint || Color::White
    end

    def color : Color
      @text_sdl.color
    end

    def color=(color : Color)
      @text_sdl.color = color
    end

    def center(width : Num, height : Num)
      @x = width / 2_f32
      @y = height / 2_f32
    end

    def update(dt : Float32)
      update_tweens(dt)
    end

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
        renderer = Text.renderer
        old_scale = renderer.scale
        renderer.scale = {scale_x.to_f32, scale_y.to_f32}

        # We must divide our coordinates by the scale
        # because the renderer's scale multiplies them
        @text_sdl.draw(draw_x.to_f32 / scale_x.to_f32, draw_y.to_f32 / scale_y.to_f32)

        renderer.scale = old_scale
      end
    end

    def destroy
      @text_sdl.text_engine.destroy
      @text_sdl.destroy
    end
  end
end
