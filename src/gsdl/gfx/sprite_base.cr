module GSDL
  abstract class SpriteBase
    include Collidable

    property x : Num
    property y : Num
    property z_index : Int32 = 0
    property color : Color = Color::White
    property collision_bounding_box : FRect
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}

    @texture : SDL3::Texture

    delegate size, to: @texture

    def initialize(@key : String, @x : Num = 0, @y : Num = 0, @origin = {0_f32, 0_f32}, @scale = {1_f32, 1_f32})
      @texture = TextureManager.get(@key)
      @collision_bounding_box = FRect.new(
        x: 0,
        y: 0,
        w: draw_width.to_f32,
        h: draw_height.to_f32
      )
    end

    abstract def width : Num
    abstract def height : Num

    def origin_x : Float32
      origin[0]
    end

    def origin_y : Float32
      origin[1]
    end

    def scale_x : Num
      scale[0]
    end

    def scale_y : Num
      scale[1]
    end

    def scale_x=(val : Num)
      @scale = {val, scale_y}
    end

    def scale_y=(val : Num)
      @scale = {scale_x, val}
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

    def center(width : Num, height : Num)
      @x = width / 2_f32
      @y = height / 2_f32
      @origin = {0.5_f32, 0.5_f32}
    end
  end
end
