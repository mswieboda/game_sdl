module GSDL
  module MathUtils
    enum Easing
      Linear
      EaseIn
      EaseOut
      EaseInOut
    end

    def self.lerp(a : Float32, b : Float32, t : Float32) : Float32
      a + (b - a) * t
    end

    def self.apply_easing(t : Float32, easing : Easing) : Float32
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
