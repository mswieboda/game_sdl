require "./centerable"

module GSDL
  abstract class SpriteBase
    include Centerable
    include Collidable
    include Area
    include Directionable
    include Tweenable

    property x : Num
    property y : Num
    property z_index : Int32 = 0
    property rotation : Num = 0
    property tint : Color? = nil
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    property update_off_screen : Bool = true

    property? flip_h : Bool = false
    property? flip_v : Bool = false
    property? draw_relative_to_camera : Bool = true

    getter tweens : Array(Tween) = [] of Tween

    @texture : Texture

    def size : Tuple(Float32, Float32)
      @texture.size
    end

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

    def on_screen? : Bool
      cam_rect = Game.camera.viewport_rect
      sx = draw_x
      sy = draw_y
      sw = draw_width
      sh = draw_height

      sx + sw >= cam_rect.x && sx <= cam_rect.x + cam_rect.w && sy + sh >= cam_rect.y && sy <= cam_rect.y + cam_rect.h
    end

    # Base update logic for all sprites.
    # Returns `true` if the sprite is on-screen and should continue updating,
    # or `false` if the subclass should abort its update.
    #
    # ALWAYS call `return unless super(dt)` at the top of your custom `update` methods.
    def update(dt : Float32) : Bool
      return false if !@update_off_screen && !on_screen?
      update_tweens(dt)
      true
    end

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

    abstract def draw(draw : Draw)
  end
end
