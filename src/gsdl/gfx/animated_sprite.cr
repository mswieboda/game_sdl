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
    delegate paused?, to: @animation_player
    delegate playing?, to: @animation_player
    delegate frame_index, to: @animation_player
    delegate :"frame_index=", to: @animation_player

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
      return unless super(dt)
      @animation_player.update(dt)
    end

    def draw(draw : Draw)
      return unless visible?
      @children.each &.draw(draw)

      texture_width = size[0]
      columns = (texture_width / @width).to_i

      frame_x = (@animation_player.frame_id % columns) * @width
      frame_y = (@animation_player.frame_id / columns).floor * @height

      epsilon = 0.5_f32
      source_rect = FRect.new(
        x: frame_x.to_f32 + epsilon,
        y: frame_y.to_f32 + epsilon,
        w: @width.to_f32 - (epsilon * 2.0_f32),
        h: @height.to_f32 - (epsilon * 2.0_f32)
      )

      dest_rect = FRect.new(
        x: render_x,
        y: render_y,
        w: render_width,
        h: render_height
      )

      flip_val = 0
      flip_val |= 1 if flip_h?
      flip_val |= 2 if flip_v?

      draw.texture_rotated(
        texture: @texture,
        source_rect: source_rect,
        dest_rect: dest_rect,
        angle: rotation,
        center: center_point_from_origin,
        flip: flip_val,
        tint: tint,
        z_index: z_index,
        sort_y: ground_y.to_f32
      )
    end
  end
end
