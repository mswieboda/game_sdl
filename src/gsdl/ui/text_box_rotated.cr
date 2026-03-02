require "./text_box"

module GSDL
  class TextBoxRotated
    include Centerable
    include Tweenable

    Padding = 16

    getter width : Int32
    getter height : Int32
    getter padding : Int32
    getter tweens : Array(Tween) = [] of Tween

    @text : TextRotated
    @x : Num = 0_f32
    @y : Num = 0_f32
    @origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    @scale : Tuple(Num, Num) = {1_f32, 1_f32}
    @rotation : Num = 0.0

    @width_fixed : Bool = false
    @height_fixed : Bool = false

    @z_index : Int32 = 900

    delegate z_index, to: @text

    def initialize(
      font = Font.default,
      text : String = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = nil,
      height : Int32? = nil,
      @padding = Padding,
      align = Font::Align::Left,
      x : Num = 0_f32,
      y : Num = 0_f32,
      color = Color::Black,
      @rotation : Num = 0.0,
      @z_index : Int32 = 900
    )
      @text = TextRotated.new(
        font: font,
        text: text,
        origin: origin,
        scale: scale,
        color: color,
        align: align,
        wrap_width: width ? width - padding * 2 : 0,
        z_index: z_index,
        rotation: rotation
      )
      @text.wrap_whitespace_visible = true

      @x = x
      @y = y
      @origin = origin
      @scale = scale

      if w = width
        @width = w
        @width_fixed = true
      else
        @width = (@text.width + padding * 2).to_i
      end

      if h = height
        @height = h
        @height_fixed = true
      else
        @height = (@text.height + padding * 2).to_i
      end

      update_text_position
    end

    private def update_text_position
      offset_x = padding * scale_x * (1.0_f32 - 2.0_f32 * origin_x)
      offset_y = padding * scale_y * (1.0_f32 - 2.0_f32 * origin_y)

      rad = @rotation.to_f64 * (Math::PI / 180.0)
      cos_a = Math.cos(rad)
      sin_a = Math.sin(rad)

      rot_offset_x = offset_x * cos_a - offset_y * sin_a
      rot_offset_y = offset_x * sin_a + offset_y * cos_a

      @text.x = @x + rot_offset_x
      @text.y = @y + rot_offset_y
      @text.origin = @origin
      @text.scale = @scale
      @text.rotation = @rotation
      @text.z_index = @z_index
    end

    def x=(x : Num)
      @x = x
      update_text_position
    end

    def y=(y : Num)
      @y = y
      update_text_position
    end

    def rotation=(rotation : Num)
      @rotation = rotation
      update_text_position
    end

    def rotation : Num
      @rotation
    end

    def z_index=(z_index : Int32)
      @z_index = z_index
      @text.z_index = z_index
    end

    def origin=(origin : Tuple(Float32, Float32))
      @origin = origin
      update_text_position
    end

    def origin_x=(origin_x : Float32)
      self.origin = {origin_x, origin_y}
    end

    def origin_y=(origin_y : Float32)
      self.origin = {origin_x, origin_y}
    end

    def scale=(scale : Tuple(Num, Num))
      @scale = scale
      update_text_position
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

    def text=(text : String)
      @text.text = text
      on_content_changed
    end

    def text
      @text.text
    end

    def x : Num; @x; end
    def y : Num; @y; end
    def z_index : Int32; @z_index; end
    def scale : Tuple(Num, Num); @scale; end
    def origin : Tuple(Float32, Float32); @origin; end

    def origin_x : Float32; origin[0]; end
    def origin_y : Float32; origin[1]; end
    def scale_x : Num; scale[0]; end
    def scale_y : Num; scale[1]; end

    def draw_width : Num; width * scale_x; end
    def draw_height : Num; height * scale_y; end

    def draw_x : Num; x - (draw_width * origin_x); end
    def draw_y : Num; y - (draw_height * origin_y); end

    private def on_content_changed
      unless @width_fixed
        @width = (@text.width + padding * 2).to_i
      end
      unless @height_fixed
        @height = (@text.height + padding * 2).to_i
      end
      update_text_position
    end

    def update(dt : Float32)
      update_tweens(dt)
      @text.update(dt)
    end

    def draw_background(draw : Draw)
    end

    def draw_border(draw : Draw)
    end

    def draw(draw : Draw)
      draw_background(draw)
      draw_border(draw)

      @text.draw(draw)
    end
  end
end
