class GSDL::AnimatedSprite
  property x : Float32
  property y : Float32
  getter texture : SDL3::Texture
  getter width : Int32
  getter height : Int32

  @key : String
  @animations = Hash(String, Animation).new
  @animation_player = AnimationPlayer.new

  delegate add, to: @animation_player
  delegate play, to: @animation_player
  delegate pause, to: @animation_player

  def initialize(@key : String, @width : Int32, @height : Int32, @x = 0_f32, @y = 0_f32)
    @texture = TextureManager.get(@key)
  end

  def center(width : Int32 | Float32, height : Int32 | Float32)
    @x = (width - @width) / 2_f32
    @y = (height - @height) / 2_f32
  end

  def update(dt : Float32)
    @animation_player.update(dt)
  end

  def draw(renderer : SDL3::Renderer)
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
