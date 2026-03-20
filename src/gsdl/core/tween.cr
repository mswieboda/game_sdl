module GSDL
  class Tween
    alias PropertyValue = Float32 | Color | Tuple(Float32, Float32)
    alias SequenceValue = PropertyValue | String | Symbol | Float64 | Int32 | Hash(Symbol, Float32) | Hash(String, Float32) | GSDL::MathUtils::Easing

    enum Property
      X
      Y
      OffsetX
      OffsetY
      ZIndex
      Rotation
      Scale
      ScaleX
      ScaleY
      ScrollSpeedX
      ScrollSpeedY
      Tint
      Color
      Value
      Unknown

      def self.from_s(name : String | Symbol) : Property
        case name.to_s.underscore
        when "x"              then X
        when "y"              then Y
        when "offset_x"       then OffsetX
        when "offset_y"       then OffsetY
        when "z_index"        then ZIndex
        when "rotation"       then Rotation
        when "scale"          then Scale
        when "scale_x"        then ScaleX
        when "scale_y"        then ScaleY
        when "scroll_speed_x" then ScrollSpeedX
        when "scroll_speed_y" then ScrollSpeedY
        when "tint"           then Tint
        when "color"          then Color
        when "value"          then Value
        else                       Unknown
        end
      end
    end

    struct Keyframe
      property duration : Float32
      property properties : Hash(Property, PropertyValue)
      property easing : GSDL::MathUtils::Easing

      def initialize(
        @duration : Float32,
        @properties : Hash(Property, PropertyValue),
        @easing : GSDL::MathUtils::Easing = GSDL::MathUtils::Easing::Linear
      )
      end
    end

    @keyframes = [] of Keyframe
    @current_keyframe_index = 0
    @elapsed_time = 0_f32
    @start_properties = Hash(Property, PropertyValue).new
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
        when GSDL::MathUtils::Easing
          easing_val
        when Symbol, String
          case easing_val.to_s.underscore
          when "ease_in"
            GSDL::MathUtils::Easing::EaseIn
          when "ease_out"
            GSDL::MathUtils::Easing::EaseOut
          when "ease_in_out"
            GSDL::MathUtils::Easing::EaseInOut
          else
            GSDL::MathUtils::Easing::Linear
          end
        else
          GSDL::MathUtils::Easing::Linear
        end

        properties = Hash(Property, PropertyValue).new
        step.each do |key, value|
          next if key == "duration" || key == "easing"

          prop = Property.from_s(key)
          next if prop.unknown?

          if value.is_a?(Hash)
            value.each do |sub_key, sub_val|
              if sub_val.is_a?(Number)
                sub_prop = Property.from_s(sub_key)
                next if sub_prop.unknown?
                properties[sub_prop] = sub_val.to_f32
              end
            end
          elsif value.is_a?(Number)
            properties[prop] = value.to_f32
          elsif value.is_a?(Color) || value.is_a?(Tuple)
            properties[prop] = value.as(PropertyValue)
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

    private def get_property(prop : Property) : PropertyValue
      case prop
      when Property::X              then @target.x.to_f32
      when Property::Y              then @target.y.to_f32
      when Property::OffsetX        then @target.offset_x.to_f32
      when Property::OffsetY        then @target.offset_y.to_f32
      when Property::ZIndex         then @target.z_index.to_f32
      when Property::Rotation       then @target.rotation.to_f32
      when Property::Scale          then @target.scale.try { |s| {s[0].to_f32, s[1].to_f32} } || {1_f32, 1_f32}
      when Property::ScaleX         then @target.scale_x.to_f32
      when Property::ScaleY         then @target.scale_y.to_f32
      when Property::ScrollSpeedX   then @target.scroll_speed_x.to_f32
      when Property::ScrollSpeedY   then @target.scroll_speed_y.to_f32
      when Property::Tint           then @target.tint || Color::White
      when Property::Color          then @target.color
      when Property::Value          then @target.value.to_f32
      else                               0_f32
      end
    end

    private def set_property(prop : Property, value : PropertyValue)
      case prop
      when Property::X
        @target.x = value.as(Float32)
      when Property::Y
        @target.y = value.as(Float32)
      when Property::OffsetX
        @target.offset_x = value.as(Float32)
      when Property::OffsetY
        @target.offset_y = value.as(Float32)
      when Property::ZIndex
        @target.z_index = value.as(Float32).to_i
      when Property::Rotation
        @target.rotation = value.as(Float32)
      when Property::Scale
        if val = value.as?(Tuple(Float32, Float32))
          @target.scale = {val[0], val[1]}
        elsif val = value.as?(Float32)
          @target.scale = {val, val}
        end
      when Property::ScaleX
        @target.scale_x = value.as(Float32)
      when Property::ScaleY
        @target.scale_y = value.as(Float32)
      when Property::ScrollSpeedX
        @target.scroll_speed_x = value.as(Float32)
      when Property::ScrollSpeedY
        @target.scroll_speed_y = value.as(Float32)
      when Property::Tint
        @target.tint = value.as(Color)
      when Property::Color
        @target.color = value.as(Color)
      when Property::Value
        @target.value = value.as(Float32)
      else
        # nothing
      end
    end

    def update(dt : Float32)
      return unless @running
      return if @keyframes.empty?

      keyframe = @keyframes[@current_keyframe_index]
      @elapsed_time += dt

      t = (keyframe.duration > 0) ? (@elapsed_time / keyframe.duration) : 1_f32
      t = 1_f32 if t > 1_f32

      eased_t = GSDL::MathUtils.apply_easing(t, keyframe.easing)

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
        return GSDL::MathUtils.lerp(start, finish, t)
      elsif start.is_a?(Color) && finish.is_a?(Color)
        return GSDL.color(
          r: (GSDL::MathUtils.lerp(start.r.to_f32, finish.r.to_f32, t)).to_u8,
          g: (GSDL::MathUtils.lerp(start.g.to_f32, finish.g.to_f32, t)).to_u8,
          b: (GSDL::MathUtils.lerp(start.b.to_f32, finish.b.to_f32, t)).to_u8,
          a: (GSDL::MathUtils.lerp(start.a.to_f32, finish.a.to_f32, t)).to_u8,
        )
      else
        # Handle cases where one might be a Tuple and other a Float32 (for scale)
        s_val = start.is_a?(Tuple(Float32, Float32)) ? start : {start.as(Float32), start.as(Float32)}
        f_val = finish.is_a?(Tuple(Float32, Float32)) ? finish : {finish.as(Float32), finish.as(Float32)}

        return {
          GSDL::MathUtils.lerp(s_val[0], f_val[0], t),
          GSDL::MathUtils.lerp(s_val[1], f_val[1], t),
        }
      end
    end
  end
end
