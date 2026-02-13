abstract class GSDL::SpriteBase
  include GSDL::Collidable

  property x : Float32
  property y : Float32
  property collision_box : SDL3::FRect
  getter texture : SDL3::Texture

  delegate size, to: @texture

  def initialize(@key : String, @x = 0_f32, @y = 0_f32)
    @texture = TextureManager.get(@key)
    @collision_box = SDL3::FRect.new(x: x, y: y, w: width.to_f32, h: height.to_f32)
  end

  abstract def width : Int32
  abstract def height : Int32

  def center(width : Int32 | Float32, height : Int32 | Float32)
    @x = (width - self.width) / 2_f32
    @y = (height - self.height) / 2_f32
  end
end
