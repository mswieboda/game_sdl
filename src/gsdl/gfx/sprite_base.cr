require "./centerable"

module GSDL
  abstract class SpriteBase < Entity
    include Centerable
    include Collidable
    include Area
    include Directionable

    property rotation : Num = 0
    property tint : Color? = nil
    property update_off_screen : Bool = true

    property? flip_h : Bool = false
    property? flip_v : Bool = false
    property? draw_relative_to_camera : Bool = true

    property render_offset_y : Float32 = 0_f32

    getter texture : Texture

    @key : Symbol

    def size : Tuple(Float32, Float32)
      @texture.size
    end

    def initialize(
      @key : Symbol,
      x : Num = 0,
      y : Num = 0,
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      @tint : Color? = nil
    )
      @texture = TextureManager.get(@key)
      @x = x
      @y = y
      @origin = origin
      @scale = scale
    end

    abstract def width : Num
    abstract def height : Num

    def on_screen? : Bool
      cam = Game.camera
      view = cam.viewport_rect

      rw = render_width
      rh = render_height
      gx = global_x
      gy = global_y

      sx = gx - (rw * origin_x)
      sy = gy - (rh * origin_y) + render_offset_y

      sx + rw >= view.x && sx <= view.x + view.w && sy + rh >= view.y && sy <= view.y + view.h
    end

    # Base update logic for all sprites.
    # Returns `true` if the sprite is on-screen and should continue updating,
    # or `false` if the subclass should abort its update.
    #
    # ALWAYS call `return unless super(dt)` at the top of your custom `update` methods.
    def update(dt : Float32) : Bool
      return false unless super(dt)
      return false if !@update_off_screen && !on_screen?
      true
    end

    # override this method in parent class for custom area box
    def area_bounding_box : FRect
      FRect.new(
        w: render_width,
        h: render_height
      )
    end

    # override this method in parent class for custom collision box
    def collision_bounding_box : FRect
      FRect.new(
        w: render_width,
        h: render_height
      )
    end

    @[AlwaysInline]
    def render_width : Num
      width * scale_x
    end

    @[AlwaysInline]
    def render_height : Num
      height * scale_y
    end

    @[AlwaysInline]
    def render_x : Num
      global_x - (render_width * origin_x)
    end

    @[AlwaysInline]
    def render_y : Num
      global_y - (render_height * origin_y) + render_offset_y
    end

    # The ground position (bottom) of the sprite, ignoring any height/oblique offsets.
    # Used for depth sorting in 3/4 perspective.
    def ground_y : Num
      render_y - render_offset_y + render_height
    end

    abstract def draw(draw : Draw)
  end
end
