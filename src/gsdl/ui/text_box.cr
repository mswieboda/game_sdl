module GSDL
  class TextBox
    include Centerable
    include Tweenable

    Padding = 16

    getter width : Int32
    getter height : Int32
    getter padding : Int32
    getter tweens : Array(Tween) = [] of Tween

    @text : TextBase
    @x : Num = 0_f32
    @y : Num = 0_f32
    @origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    @scale : Tuple(Num, Num) = {1_f32, 1_f32}

    # Explicitly store whether width/height were set manually
    @width_fixed : Bool = false
    @height_fixed : Bool = false

    @z_index : Int32 = 900
    property? draw_relative_to_camera : Bool = false

    delegate z_index, to: @text

    def initialize(
      font = Font.default,
      text : String | TextBase = "",
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      width : Int32? = nil,
      height : Int32? = nil,
      @padding = Padding,
      align = Font::Align::Left,
      x : Num = 0_f32,
      y : Num = 0_f32,
      color = Color::Black,
      @z_index : Int32 = 900,
      @draw_relative_to_camera : Bool = false
    )
      if text.is_a?(String)
        @text = Text.new(
          font: font,
          text: text,
          origin: origin,
          scale: scale,
          color: color,
          align: align,
          wrap_width: width ? width - padding * 2 : 0,
          z_index: z_index
        )
      else
        @text = text
        # Override properties to match the box if they were provided (or rely on the custom text's own layout)
        @text.wrap_width = width - padding * 2 if width
        @text.z_index = z_index
      end

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
      # Formula derived to keep text padded within box regardless of origin:
      # text_x = x + padding * scale_x * (1 - 2 * origin_x)
      @text.x = @x + padding * scale_x * (1.0_f32 - 2.0_f32 * origin_x)
      @text.y = @y + padding * scale_y * (1.0_f32 - 2.0_f32 * origin_y)
      @text.origin = @origin
      @text.scale = @scale
      @text.z_index = @z_index
      @text.draw_relative_to_camera = self.draw_relative_to_camera?
    end

    def x=(x : Num)
      @x = x
      update_text_position
    end

    def y=(y : Num)
      @y = y
      update_text_position
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

    def draw_x : Num
      dx = x - (draw_width * origin_x)
      draw_relative_to_camera? ? dx - Game.camera.x : dx
    end

    def draw_y : Num
      dy = y - (draw_height * origin_y)
      draw_relative_to_camera? ? dy - Game.camera.y : dy
    end

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

      # Track text dimensions to detect changes (like in TextTyped)
      old_w = @text.width
      old_h = @text.height

      @text.update(dt)

      # If text changed size, we need to update our box dimensions and text position
      if @text.width != old_w || @text.height != old_h
        on_content_changed
      end
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
