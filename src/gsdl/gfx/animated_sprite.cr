require "./sprite_base"

module GSDL
  class AnimatedSprite < SpriteBase
    getter width : Int32
    getter height : Int32

    @animations = Hash(String, Animation).new
    @animation_player = AnimationPlayer.new

    delegate add, to: @animation_player
    delegate play, to: @animation_player
    delegate pause, to: @animation_player
    delegate playing?, to: @animation_player

    def initialize(
      key : String,
      @width : Int32,
      @height : Int32,
      x : Num = 0,
      y : Num = 0,
      origin = {0_f32, 0_f32},
      scale = {1_f32, 1_f32},
      tint : Color? = nil
    )
      super(key: key, x: x, y: y, origin: origin, scale: scale, tint: tint)
    end

    def update(dt : Float32)
      @animation_player.update(dt)
    end

    def draw(draw : Draw, camera_x : Float32 = 0_f32, camera_y : Float32 = 0_f32, flip_horizontal : Bool = false)
      texture_width = size[0]
      columns = (texture_width / @width).to_i

      frame_x = (@animation_player.frame_id % columns) * @width
      frame_y = (@animation_player.frame_id / columns).floor * @height

      source_rect = FRect.new(
        x: frame_x.to_f32,
        y: frame_y.to_f32,
        w: @width.to_f32,
        h: @height.to_f32
      )

      dest_rect = FRect.new(
        x: draw_x.to_f32 - camera_x,
        y: draw_y.to_f32 - camera_y,
        w: draw_width.to_f32,
        h: draw_height.to_f32
      )

      draw.texture_rotated(
        texture: @texture,
        source_rect: source_rect,
        dest_rect: dest_rect,
        flip: flip_horizontal ? 1 : 0,
        z_index: z_index,
        tint: tint
      )
    end
  end
end
