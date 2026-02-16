module GSDL
  class Text
    property text
    property x : Float32
    property y : Float32

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
      color = GSDL::Colors::White,
      direction = SDL3::TTF::Direction::LTR,
      wrap_width : Int32? = nil
    )
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

    def center(width : Int32 | Float32, height : Int32 | Float32)
      @x = ((width - self.width) / 2).to_f32
      @y = ((height - self.height) / 2).to_f32
    end

    def update(dt : Float32)
    end

    def draw(draw : Draw)
      return if @text.empty?

      draw.text(self)
    end

    # NOTE: shouldn't be used outside of Draw class, but Draw needs it public
    #   to access the `@text_sdl` internally here
    def _draw
      @text_sdl.draw(x, y)
    end

    def destroy
      @text_sdl.text_engine.destroy
      @text_sdl.destroy
    end
  end
end
