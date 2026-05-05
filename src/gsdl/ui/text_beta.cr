module GSDL
  class TextBeta < Entity
    # include Centerable

    property text : String
    property z_index : Int32

    getter font_size : Float32

    def initialize(
      font_path = "./assets/fonts/PressStart2P.ttf",
      @font_size = 32_f32,
      @text = "foo",
      @x = 0,
      @y = 0,
      @color = GSDL::Color::White,
      @z_index = 0,
    )
      @font_atlas = GSDL::FontAtlas.new(font_path, @font_size)
    end

    def draw(draw : Draw)
      @font_atlas.draw_text(text: @text, x: @x, y: @y, color: @color, z_index: @z_index)
    end
  end
end
