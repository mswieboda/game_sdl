class GSDL::Animation
  getter name : String = ""
  getter frames : Array(Int32)
  getter frame_time : Float32 # Time per frame in seconds
  getter? loops : Bool

  def initialize(@name = "", @frames = [0], @frame_time = 0_f32, @loops = true)
  end
end
