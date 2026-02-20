module GSDL
  class Tween
    enum Easing
      Linear
      EaseIn
      EaseOut
      EaseInOut
    end

    alias PropertyValue = Float32 | Color | Tuple(Float32, Float32)
    alias SequenceValue = PropertyValue | String | Symbol | Float64 | Int32 | Hash(Symbol, Float32) | Hash(String, Float32) | Easing

    struct Keyframe
      property duration : Float32
      property properties : Hash(String, PropertyValue)
      property easing : Easing

      def initialize(
        @duration : Float32,
        @properties : Hash(String, PropertyValue),
        @easing : Easing = Easing::Linear
      )
      end
    end

    @keyframes = [] of Keyframe
    @current_keyframe_index = 0
    @elapsed_time = 0_f32
    @start_properties = Hash(String, PropertyValue).new
    @running = false
    @loop = false

    getter? running

    def initialize(@target : Tweenable)
    end

    def add_sequence(sequence : Array(Hash(String, SequenceValue)))
      sequence.each do |step|
        duration = step["duration"]?.as?(Float32 | Float64 | Int32).try(&.to_f32) || 0_f32
        easing_val = step["easing"]?
        easing = case easing_val
        when Easing
          easing_val
        when Symbol, String
          case easing_val.to_s.underscore
          when "ease_in"
            Easing::EaseIn
          when "ease_out"
            Easing::EaseOut
          when "ease_in_out"
            Easing::EaseInOut
          else
            Easing::Linear
          end
        else
          Easing::Linear
        end

        properties = Hash(String, PropertyValue).new
        step.each do |key, value|
          next if key == "duration" || key == "easing"

          if value.is_a?(Hash)
            value.each do |sub_key, sub_val|
              if sub_val.is_a?(Number)
                properties[sub_key.to_s] = sub_val.to_f32
              end
            end
          elsif value.is_a?(Number)
            properties[key.to_s] = value.to_f32
          elsif value.is_a?(Color) || value.is_a?(Tuple)
            properties[key.to_s] = value.as(PropertyValue)
          end
        end

        @keyframes << Keyframe.new(duration, properties, easing)
      end
    end

    def start(loop : Bool = false)
      return if @keyframes.empty?

      @loop = loop
      @current_keyframe_index = 0
      @elapsed_time = 0_f32
      @running = true
      prepare_next_keyframe
      self
    end

    def stop
      @running = false
      self
    end

    private def prepare_next_keyframe
      return if @current_keyframe_index >= @keyframes.size

      keyframe = @keyframes[@current_keyframe_index]
      @start_properties.clear

      keyframe.properties.each_key do |prop|
        @start_properties[prop] = get_property(prop)
      end
    end

    private def get_property(prop : String) : PropertyValue
      case prop
      when "x"       then @target.x.to_f32
      when "y"       then @target.y.to_f32
      when "z_index" then @target.z_index.to_f32
      when "rotation" then @target.rotation.to_f32
      when "scale"   then @target.scale.try { |s| {s[0].to_f32, s[1].to_f32} } || {1_f32, 1_f32}
      when "scale_x" then @target.scale_x.to_f32
      when "scale_y" then @target.scale_y.to_f32
      when "tint"    then @target.tint || Color::White
      when "color"   then @target.color
      else                0_f32
      end
    end

    private def set_property(prop : String, value : PropertyValue)
      case prop
      when "x"
        @target.x = value.as(Float32)
      when "y"
        @target.y = value.as(Float32)
      when "z_index"
        @target.z_index = value.as(Float32).to_i
      when "rotation"
        @target.rotation = value.as(Float32)
      when "scale"
        if val = value.as?(Tuple(Float32, Float32))
          @target.scale = {val[0], val[1]}
        elsif val = value.as?(Float32)
          @target.scale = {val, val}
        end
      when "scale_x"
        @target.scale_x = value.as(Float32)
      when "scale_y"
        @target.scale_y = value.as(Float32)
      when "tint"
        @target.tint = value.as(Color)
      when "color"
        @target.color = value.as(Color)
      end
    end

    def update(dt : Float32)
      return unless @running
      return if @keyframes.empty?

      keyframe = @keyframes[@current_keyframe_index]
      @elapsed_time += dt

      t = (keyframe.duration > 0) ? (@elapsed_time / keyframe.duration) : 1_f32
      t = 1_f32 if t > 1_f32

      eased_t = apply_easing(t, keyframe.easing)

      keyframe.properties.each do |prop, end_value|
        start_value = @start_properties[prop]
        set_property(prop, lerp(start_value, end_value, eased_t))
      end

      if t >= 1_f32
        @current_keyframe_index += 1
        @elapsed_time = 0_f32

        if @current_keyframe_index >= @keyframes.size
          if @loop
            @current_keyframe_index = 0
            prepare_next_keyframe
          else
            @running = false
          end
        else
          prepare_next_keyframe
        end
      end
    end

    private def lerp(start : PropertyValue, finish : PropertyValue, t : Float32) : PropertyValue
      if start.is_a?(Float32) && finish.is_a?(Float32)
        return start + (finish - start) * t
      elsif start.is_a?(Color) && finish.is_a?(Color)
        return GSDL.color(
          r: (start.r.to_f32 + (finish.r.to_f32 - start.r.to_f32) * t).to_u8,
          g: (start.g.to_f32 + (finish.g.to_f32 - start.g.to_f32) * t).to_u8,
          b: (start.b.to_f32 + (finish.b.to_f32 - start.b.to_f32) * t).to_u8,
          a: (start.a.to_f32 + (finish.a.to_f32 - start.a.to_f32) * t).to_u8,
        )
      else
        # Handle cases where one might be a Tuple and other a Float32 (for scale)
        s_val = start.is_a?(Tuple(Float32, Float32)) ? start : {start.as(Float32), start.as(Float32)}
        f_val = finish.is_a?(Tuple(Float32, Float32)) ? finish : {finish.as(Float32), finish.as(Float32)}
        
        return {
          s_val[0] + (f_val[0] - s_val[0]) * t,
          s_val[1] + (f_val[1] - s_val[1]) * t,
        }
      end
    end

    private def apply_easing(t : Float32, easing : Easing) : Float32
      case easing
      when Easing::Linear
        t
      when Easing::EaseIn
        t * t
      when Easing::EaseOut
        t * (2 - t)
      when Easing::EaseInOut
        t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t
      else
        t
      end
    end
  end
end
