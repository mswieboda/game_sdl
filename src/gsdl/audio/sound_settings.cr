module GSDL
  class SoundSettings
    @@master_volume : Float32 = 1.0_f32
    @@category_volumes : Hash(String, Float32) = Hash(String, Float32).new(1.0_f32)

    def self.master_volume : Float32
      @@master_volume
    end

    def self.master_volume=(value : Float32)
      @@master_volume = value.clamp(0.0_f32, 2.0_f32) # Allow up to 2x boost if SDL3 allows
      LibSDL3Mixer.set_mixer_gain(AudioManager.mixer, @@master_volume)
    end

    def self.get_volume(category : String) : Float32
      @@category_volumes[category]
    end

    def self.set_volume(category : String, value : Float32)
      val = value.clamp(0.0_f32, 2.0_f32)
      @@category_volumes[category] = val
      LibSDL3Mixer.set_tag_gain(AudioManager.mixer, category.to_unsafe, val)
    end
  end
end
