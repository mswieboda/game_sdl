module GSDL
  module Tweenable
    def tween : Tween
      t = Tween.new(self)
      tweens << t
      t
    end

    def tween(to : Hash(Symbol, Tween::PropertyValue), duration : Float32, easing : MathUtils::Easing = MathUtils::Easing::Linear)
      t = tween
      step = Hash(Symbol, Tween::SequenceValue).new
      step[:duration] = duration
      step[:easing] = easing
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

    def _tween_color_prop : Symbol
      self.is_a?(SpriteBase) ? :tint : :color
    end

    def flash(flash_color : Color = Color::Red, duration : Float32 = 0.1_f32, count : Int32 = 3)
      t = tween
      prop = _tween_color_prop
      orig_color = prop == :tint ? (tint || Color::White) : color
      seq = [] of Hash(Symbol, Tween::SequenceValue)

      count.times do
        seq << {:duration => duration, prop => flash_color.as(Tween::SequenceValue)}
        seq << {:duration => duration, prop => orig_color.as(Tween::SequenceValue)}
      end

      t.add_sequence(seq)
      t.start
      t
    end

    def pulse(scale_factor : Float32 = 1.2_f32, duration : Float32 = 0.5_f32)
      t = tween
      orig_scale = self.scale

      seq = [
        {:duration => duration / 2.0_f32, :scale => {orig_scale[0].to_f32 * scale_factor, orig_scale[1].to_f32 * scale_factor}.as(Tween::SequenceValue), :easing => :ease_out},
        {:duration => duration / 2.0_f32, :scale => {orig_scale[0].to_f32, orig_scale[1].to_f32}.as(Tween::SequenceValue), :easing => :ease_in}
      ]

      t.add_sequence(seq)
      t.start
      t
    end

    def spin(duration : Float32 = 1.0_f32, direction : Symbol = :clockwise)
      t = tween
      orig_rot = self.rotation.to_f32
      target_rot = direction == :clockwise ? orig_rot + 360.0_f32 : orig_rot - 360.0_f32

      seq = [
        {:duration => duration, :rotation => target_rot.as(Tween::SequenceValue)}
      ]

      t.add_sequence(seq)
      t.start
      t
    end

    def shake(intensity : Float32 = 10.0_f32, duration : Float32 = 0.5_f32)
      t = tween
      orig_x = self.x.to_f32
      orig_y = self.y.to_f32

      steps = 10
      step_duration = duration / steps

      seq = [] of Hash(Symbol, Tween::SequenceValue)
      (steps - 1).times do
        seq << {
          :duration => step_duration,
          :x => (orig_x + (rand - 0.5_f32) * intensity * 2).as(Tween::SequenceValue),
          :y => (orig_y + (rand - 0.5_f32) * intensity * 2).as(Tween::SequenceValue)
        }
      end

      seq << {
        :duration => step_duration,
        :x => orig_x.as(Tween::SequenceValue),
        :y => orig_y.as(Tween::SequenceValue)
      }

      t.add_sequence(seq)
      t.start
      t
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
    def offset_x : Num
      0_f32
    end

    def offset_x=(val : Num); end

    def offset_y : Num
      0_f32
    end

    def offset_y=(val : Num); end

    def rotation : Num
      0.0_f32
    end

    def rotation=(rotation : Num); end

    def scroll_speed_x : Num
      0_f32
    end

    def scroll_speed_x=(val : Num); end

    def scroll_speed_y : Num
      0_f32
    end

    def scroll_speed_y=(val : Num); end

    def tint : Color?
      nil
    end

    def tint=(val : Color?); end

    def color : Color
      Color::White
    end

    def color=(val : Color); end

    def value : Num
      0_f32
    end

    def value=(val : Num); end
  end
end
