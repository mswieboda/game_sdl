class GSDL::AnimationPlayer
  property frame_index = 0
  property elapsed_time = 0_f32
  getter animations = Hash(String, Animation).new
  getter animation = Animation.new
  getter? paused : Bool = false

  def add(name, frames, fps : Int32)
    frame_time = 1 / fps.to_f32
    @animations[name] = Animation.new(name, frames, frame_time)
  end

  def play(name)
    @paused = false
    @animation = @animations[name]
    @frame_index = 0
    @elapsed_time = 0_f32
  end

  def play
    @paused = false
  end

  def pause
    @paused = true
  end

  def update(dt : Float32)
    return if paused?

    @elapsed_time += dt

    if @elapsed_time >= @animation.frame_time
      @elapsed_time = 0.0f32
      @frame_index += 1

      if @frame_index >= @animation.frames.size
        @frame_index = @animation.loops? ? 0 : @animation.frames.size - 1
      end
    end
  end

  def frame_id
    @animation.try(&.frames[@frame_index]) || 0
  end
end
