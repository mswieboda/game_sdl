module GSDL
  class FontAtlasManager
    # key: {font_path, font_size, outline}
    @@registry = Hash(Tuple(String, Float32, Int32), FontAtlas).new
    @@ref_counts = Hash(Tuple(String, Float32, Int32), Int32).new

    def self.get(path : String, size : Float32, outline : Int32) : FontAtlas
      key = {path, size, outline}

      unless @@registry.has_key?(key)
        # Bake a new one if it doesn't exist
        @@registry[key] = FontAtlas.new(path, size, outline: outline)
        @@ref_counts[key] = 0
      end

      @@ref_counts[key] += 1

      @@registry[key]
    end

    def self.release(path : String, size : Float32, outline : Int32)
      key = {path, size, outline}

      return unless @@registry.has_key?(key)

      @@ref_counts[key] -= 1

      if @@ref_counts[key] <= 0
        @@registry[key].destroy
        @@registry.delete(key)
        @@ref_counts.delete(key)
      end
    end
  end
end
