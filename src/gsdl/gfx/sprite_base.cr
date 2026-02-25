require "./centerable"

module GSDL
  abstract class SpriteBase
    include Centerable
    include Collidable
    include Area
    include Tweenable

    property x : Num
    property y : Num
    property z_index : Int32 = 0
    property rotation : Num = 0
    property tint : Color? = nil
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}

    getter tweens : Array(Tween) = [] of Tween

    @texture : Texture

    delegate size, to: @texture

    def initialize(
      @key : String,
      @x : Num = 0,
      @y : Num = 0,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @tint : Color? = nil
    )
      @texture = TextureManager.get(@key)
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

    def scale=(val : Tuple(Num, Num))
      @scale = val
    end

    def scale=(val : Num)
      @scale = {val, val}
    end

    # override this method in parent class for custom area box
    def area_bounding_box : FRect
      FRect.new(
        w: draw_width,
        h: draw_height
      )
    end

    # override this method in parent class for custom collision box
    def collision_bounding_box : FRect
      FRect.new(
        w: draw_width,
        h: draw_height
      )
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

    abstract def update(dt : Float32)

    abstract def draw(draw : Draw, camera_x : Float32 = 0_f32, camera_y : Float32 = 0_f32, flip_horizontal : Bool = false)
  end
end
