require "./sprite_base"

class GSDL::AnimatedSprite < GSDL::SpriteBase
  getter width : Int32
  getter height : Int32

  @animations = Hash(String, Animation).new
  @animation_player = AnimationPlayer.new

  delegate add, to: @animation_player
  delegate play, to: @animation_player
  delegate pause, to: @animation_player

  def initialize(key : String, @width : Int32, @height : Int32, x = 0_f32, y = 0_f32)
    super(key, x, y)
  end

  def update(dt : Float32)
    @animation_player.update(dt)
  end

  def draw(renderer : Renderer)
    source_rect = SDL3::FRect.new(
      x: @animation_player.frame_id * @width,
      y: 0_f32,
      w: @width.to_f32,
      h: @height.to_f32
    )

    dest_rect = SDL3::FRect.new(
      x: @x,
      y: @y,
      w: @width.to_f32,
      h: @height.to_f32
    )

    renderer.render_texture(texture: texture, source_rect: source_rect, dest_rect: dest_rect)
  end
end
