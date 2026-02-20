module GSDL
  module Tweenable
    def tween : Tween
      t = Tween.new(self)
      tweens << t
      t
    end

    def tween(to : Hash(String, Tween::PropertyValue), duration : Float32, easing : Tween::Easing = Tween::Easing::Linear)
      t = tween
      step = Hash(String, Tween::SequenceValue).new
      step["duration"] = duration
      step["easing"] = easing
      to.each do |k, v|
        step[k] = v.as(Tween::SequenceValue)
      end
      t.add_sequence([step])
      t.start
      t
    end

    def update_tweens(dt : Float32)
      tweens.each(&.update(dt))
      tweens.reject! { |t| !t.running? }
    end

    abstract def tweens : Array(Tween)

    abstract def x : Num
    abstract def x=(x : Num)
    abstract def y : Num
    abstract def y=(y : Num)
    abstract def z_index : Int32
    abstract def z_index=(z_index : Int32)
    abstract def scale : Tuple(Num, Num)
    abstract def scale=(scale : Tuple(Num, Num))
    abstract def scale_x : Num
    abstract def scale_x=(scale_x : Num)
    abstract def scale_y : Num
    abstract def scale_y=(scale_y : Num)

    # Optional properties with default implementations
    def tint : Color?; nil; end
    def tint=(val : Color?); end
    def color : Color; Color::White; end
    def color=(val : Color); end
  end
end
