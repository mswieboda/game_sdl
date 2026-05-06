module GSDL
  enum HorizontalAlign
    Left
    Center
    Right
  end

  enum VerticalAlign
    Top
    Center
    Bottom
  end

  class TextBeta < Entity
    # include Centerable

    property z_index : Int32
    property h_align : HorizontalAlign
    property v_align : VerticalAlign
    property line_spacing : Num

    # TODO: make a setter to change font / font path
    getter font_size : Float32

    @font_atlas : FontAtlas
    @width : Num?
    @height : Num?
    @lines : Array(String)

    def initialize(
      font_path = "./assets/fonts/PressStart2P.ttf",
      @font_size : Float32 = 16_f32, # TODO: maybe make this a Num or Int32
      text = "foo",
      @x : Num = 0,
      @y : Num = 0,
      @h_align : HorizontalAlign = HorizontalAlign::Left,
      @v_align : VerticalAlign = VerticalAlign::Top,
      @line_spacing : Num = 1.2_f32,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @color = GSDL::Color::White,
      @width = nil,
      @height = nil,
      @z_index : Int32 = 0,
    )
      @font_atlas = GSDL::FontAtlas.new(font_path, @font_size)
      @lines = text.split("\n")
    end

    def text : String
      @lines.join("\n")
    end

    def text=(text : String)
      @lines = text.split("\n")
    end

    def width : Num
      if width = @width
        return width
      end

      max_line_width = 0

      @lines.each do |line_text|
        line_width = @font_atlas.calculate_width(line_text)

        if line_width > max_line_width
          max_line_width = line_width
        end
      end

      @width = max_line_width
      @width.not_nil!
    end

    def width=(width : Num)
      if width != @width
        @width = width
      end
    end

    @[AlwaysInline]
    def line_height
      @font_size * (@lines.size > 1 ? @line_spacing : 1)
    end

    def height : Num
      if height = @height
        return height
      end

      @height = line_height * @lines.size
      @height.not_nil!
    end

    def height=(height : Num)
      if height != @height
        @height = height
      end
    end

    @[AlwaysInline]
    def render_width : Num
      width * scale_x
    end

    @[AlwaysInline]
    def render_height : Num
      height * scale_y
    end

    def draw(draw : Draw)
      @lines.each_with_index do |line_text, line_index|
        line_width = @font_atlas.calculate_width(line_text)
        offset_x = 0
        line_offset_y = line_index * line_height

        if width = @width
          offset_x = case @h_align
          when .left?
            0
          when .center?
            width / 2 - line_width / 2
          when .right?
            width - line_width
          else
            0
          end
        end

        x = @x + offset_x * scale_x - (self.width * scale_x * origin_x)
        y = @y + line_offset_y * scale_y - (self.height * scale_y * origin_y)

        @font_atlas.draw_text(
          text: line_text,
          x: x.to_f32,
          y: y.to_f32,
          color: @color,
          scale_x: scale_x,
          scale_y: scale_y,
          z_index: @z_index
        )
      end
    end
  end
end
