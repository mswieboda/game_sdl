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

    @@draw : Draw?

    # TODO: maybe rename to @internal like the other class/struct wrappers
    # however, maybe TextBase / Text are custom enough so it's okay?
    @text_sdl : SDL3::TTF::Text

    def direction : SDL3::TTF::Direction
      @text_sdl.direction
    end

    def direction=(val : SDL3::TTF::Direction)
      @text_sdl.direction = val
    end

    def font : Font
      Font.new(@text_sdl.font)
    end

    def width : Int32
      @text_sdl.width
    end

    def wrap_whitespace_visible? : Bool
      @text_sdl.wrap_whitespace_visible?
    end

    def wrap_whitespace_visible=(val : Bool)
      @text_sdl.wrap_whitespace_visible = val
    end

    def wrap_width : Int32
      @text_sdl.wrap_width
    end

    def size : Tuple(Int32, Int32)
      @text_sdl.size
    end

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
      direction = Font::Direction::LTR,
      wrap_width : Int32? = nil,
      @z_index : Int32 = 0
    )
      if font.align != align
        font = font.copy
        font.align = align
      end

      # Use the shared text_engine from the Draw instance
      @text_sdl = TextBase.draw.text_engine.create_text(font.to_sdl, @text)

      @text_sdl.color = color.to_sdl
      @text_sdl.direction = direction
      @text_sdl.font = font.to_sdl
      @text_sdl.wrap_whitespace_visible = false

      if ww = wrap_width
        @text_sdl.wrap_width = ww
      end
    end

    def self.draw=(draw : Draw)
      @@draw = draw
    end

    def self.draw : Draw
      if draw = @@draw
        draw
      else
        raise "GSDL::TextBase.draw not set, should be set via GSDL::Game.init"
      end
    end

    # NOTE: used in TextRotated for example
    def self.renderer : SDL3::Renderer
      draw.to_sdl
    end

    def text=(text : String)
      @text = text
      @text_sdl.text = text
      on_content_changed
    end

    def color : Color
      Color.new(@text_sdl.color)
    end

    def color=(color : Color)
      @text_sdl.color = color.to_sdl
      on_content_changed
    end

    def tint : Color?
      color
    end

    def tint=(tint : Color?)
      self.color = tint || Color::White
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
      @text_sdl.destroy
    end
  end
end
