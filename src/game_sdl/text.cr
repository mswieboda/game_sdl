require "./font"

module GameSDL
  class Text
    getter font
    getter text
    property x : Int32
    property y : Int32
    getter color : SDL::Color
    getter? ansi

    @surface : SDL::Surface

    delegate width, to: @surface
    delegate height, to: @surface

    def initialize(
      @font = Font.default,
      @text = "",
      @x = 0,
      @y = 0,
      @color = SDL::Color[0],
      @ansi = true
    )

      @surface = font.render_blended(text, color, ansi?)
    end

    def update(frame_time : Float32)
    end

    def draw(renderer : SDL::Renderer, window : SDL::Window)
      renderer.copy(@surface, dstrect: SDL::Rect[x, y, width, height])
    end
  end
end
