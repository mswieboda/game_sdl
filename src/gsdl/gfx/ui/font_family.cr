module GSDL
  enum FontStyle
    Regular
    Italic
    Oblique
  end

  enum FontWeight
    Light  = 300
    Normal = 400
    Medium = 500
    Bold   = 700
    Black  = 900
  end

  class FontFamily
    getter name : String
    @mappings = Hash({FontWeight, FontStyle}, String).new

    def initialize(@name : String)
    end

    def add(weight : FontWeight, style : FontStyle, path_key : String) : Nil
      @mappings[{weight, style}] = path_key
    end

    def resolve(weight : FontWeight, style : FontStyle) : String
      # 1. Try exact match
      if path = @mappings[{weight, style}]?
        return path
      end

      # 2. Match requested style with Normal weight
      if path = @mappings[{FontWeight::Normal, style}]?
        return path
      end

      # 3. Match requested weight with Regular style
      if path = @mappings[{weight, FontStyle::Regular}]?
        return path
      end

      # 4. Fallback to any first registered font variant in this family
      unless @mappings.empty?
        return @mappings.values.first
      end

      raise "FontFamily '#{name}' has no registered font mappings."
    end
  end
end
