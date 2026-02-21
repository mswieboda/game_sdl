module GSDL
  abstract class TextBase
    include Centerable
    include Tweenable

    property text : String
    property x : Num
    property y : Num
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property z_index : Int32 = 0
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    getter tweens : Array(Tween) = [] of Tween

    @@renderer : SDL3::Renderer?

    @text_sdl : SDL3::TTF::Text

    delegate direction, to: @text_sdl
    delegate :"direction=", to: @text_sdl
    delegate text_engine, to: @text_sdl
    delegate :"text_engine=", to: @text_sdl
    delegate font, to: @text_sdl
    delegate width, to: @text_sdl
    delegate wrap_whitespace_visible?, to: @text_sdl
    delegate :"wrap_whitespace_visible=", to: @text_sdl
    delegate wrap_width, to: @text_sdl
    delegate size, to: @text_sdl

    def font=(val : Font)
      @text_sdl.font = val
      on_content_changed
    end

    def wrap_width=(val : Int32)
      @text_sdl.wrap_width = val
      on_content_changed
    end

    def initialize(
      font = Font.default,
      @text = "",
      @x = 0,
      @y = 0,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
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

      text_engine = TextBase.renderer.create_text_engine
      @text_sdl = text_engine.create_text(font, @text)

      @text_sdl.color = color
      @text_sdl.direction = direction
      @text_sdl.font = font
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
      @text = text
      @text_sdl.text = text
      on_content_changed
    end

    def color : Color
      @text_sdl.color
    end

    def color=(val : Color)
      @text_sdl.color = val
      on_content_changed
    end

    def tint : Color?
      color
    end

    def tint=(val : Color?)
      self.color = val || Color::White
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

    def scale_x=(val : Num)
      self.scale = {val, scale_y}
    end

    def scale_y=(val : Num)
      self.scale = {scale_x, val}
    end

    def scale=(val : Num)
      self.scale = {val, val}
    end

    def update(dt : Float32)
      update_tweens(dt)
    end

    # Hook for subclasses to respond to text/color/font changes
    private def on_content_changed
    end

    abstract def draw(draw : Draw)
    abstract def _draw

    def destroy
      @text_sdl.text_engine.destroy
      @text_sdl.destroy
    end
  end
end
