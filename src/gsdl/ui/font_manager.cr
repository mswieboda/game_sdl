module GSDL
  module FontManager
    DefaultFontKey = :default
    DefaultFontSize = 16_f32
    DefaultOutline = 0

    # key: #{name}-#{font_size}-#{outline}
    @@fonts = Hash(String, Font).new
    @@font_data = Hash(String, Bytes).new
    @@families = Hash(String, FontFamily).new
    @@registry = Hash(Symbol, String).new
    @@cache = Hash(Tuple(Symbol, Float32, Int32, FontWeight, FontStyle), WeakRef(Font)).new
    @@mutex = Mutex.new
    @@default = DefaultFontKey

    def self.default : Symbol
      @@default
    end

    def self.default_size
      DefaultFontSize
    end

    def self.default_outline
      DefaultOutline
    end

    def self.register_family(name : String) : Nil
      family = FontFamily.new(name)
      yield family
      @@mutex.synchronize do
        @@families[name] = family
      end
    end

    def self.load_default(path_key : String, size : Float32 = DefaultFontSize, outline = DefaultOutline)
      @@default = :default
      register_pair(:default, path_key)
      load(path_key, size, outline)
    end

    # Loads a font based on the mode (release/debug).
    def self.load(path_key : String, size : Num, outline : Int32) : Font
      @@mutex.synchronize do
        font_key = get_key(get_name(path_key), size, outline)

        if @@fonts.has_key?(font_key)
          return @@fonts[font_key]
        end

        data = {% if flag?(:release) %}
          manifest_key = path_key.starts_with?("assets/") ? path_key.sub("assets/", "") : path_key
          AssetManager.load_raw_data(manifest_key)
        {% else %}
          full_path = if path_key.starts_with?("assets/") || path_key.starts_with?(GSDL::AssetManager.asset_path)
            path_key
          else
            GSDL::AssetManager.asset_path + path_key
          end
          File.open(full_path) do |file|
            slice = Bytes.new(file.size.to_i)
            file.read_fully(slice)
            slice
          end
        {% end %}

        name = get_name(path_key)
        @@font_data[name] = data

        font = Font.new(name: name, data: data, size: size, outline: outline)
        @@fonts[font_key] = font
        font
      end
    end

    def self.load_from_memory(name : String, data : Bytes, size : Num, outline : Int32) : Font
      @@mutex.synchronize do
        font_key = get_key(name, size, outline)
        if @@fonts.has_key?(font_key)
          return @@fonts[font_key]
        end

        @@font_data[name] = data

        font = Font.new(name: name, data: data, size: size, outline: outline)
        @@fonts[font_key] = font
        font
      end
    end


    def self.get(
      id : Symbol,
      size : Num,
      outline : Int32,
      weight : FontWeight = FontWeight::Normal,
      style : FontStyle = FontStyle::Regular
    ) : Font
      @@mutex.synchronize do
        cache_key = {id, size.to_f32, outline, weight, style}
        if weak_ref = @@cache[cache_key]?
          if font = weak_ref.value
            return font
          end
        end

        path_key = @@registry[id]?
        if path_key.nil?
          if id == :default && (default_sym = @@default) != :default
            path_key = @@registry[default_sym]?
          elsif @@families.has_key?(id.to_s)
            path_key = id.to_s
          else
            clean_sym = id.to_s.downcase.gsub('_', "").gsub('-', "")
            if matched_family = @@families.keys.find { |fam| fam.downcase.gsub('_', "").gsub('-', "") == clean_sym }
              path_key = matched_family
            end
          end
        end

        if path_key
          resolved_name = get_name(path_key)
          font_key = get_key(resolved_name, size, outline)
          if font = @@fonts[font_key]?
            return font
          end
        else
          font_key = get_key(id.to_s, size, outline)
          if font = @@fonts[font_key]?
            return font
          end

          # Also check by name (without extension) if id.to_s matches
          @@fonts.each_key do |fkey|
            if fkey.starts_with?("#{id.to_s}-")
              if font = @@fonts[fkey]?
                return font
              end
            end
          end

          raise "Asset Registry Error: Symbol :#{id} was never registered!"
        end

        if family = @@families[path_key]?
          resolved_path = family.resolve(weight, style)
        else
          resolved_path = path_key
        end

        resolved_name = get_name(resolved_path)

        unless @@font_data.has_key?(resolved_name)
          load_font_data_unlocked(resolved_path)
        end

        if data = @@font_data[resolved_name]?
          font = Font.new(name: resolved_name, data: data, size: size, outline: outline)
          @@cache[cache_key] = WeakRef.new(font)
          return font
        end

        raise "Font data not found for path: #{resolved_path}"
      end
    end

    # Retrieves a loaded font by its key.
    def self.get(
      name : String,
      size : Num,
      outline : Int32,
      weight : FontWeight = FontWeight::Normal,
      style : FontStyle = FontStyle::Regular
    ) : Font
      @@mutex.synchronize do
        if family = @@families[name]?
          path_key = family.resolve(weight, style)
        else
          path_key = name
        end

        resolved_name = get_name(path_key)
        font_key = get_key(resolved_name, size, outline)

        if font = @@fonts[font_key]?
          return font
        end

        unless @@font_data.has_key?(resolved_name)
          load_font_data_unlocked(path_key)
        end

        if data = @@font_data[resolved_name]?
          font = Font.new(name: resolved_name, data: data, size: size, outline: outline)
          @@fonts[font_key] = font
          return font
        end

        raise "Font with name '#{resolved_name}' (derived from '#{name}' with weight: #{weight}, style: #{style}) not found and dynamic loading failed."
      end
    end

    # Housekeeping Maintenance Pass (Call during scene transitions)
    def self.prune_dead_references : Nil
      @@mutex.synchronize do
        @@cache.select! do |key, weak_ref|
          !weak_ref.value.nil?
        end
      end
    end

    def self.unload(key : String) : Nil
      @@mutex.synchronize do
        if font = @@fonts.delete(key)
          font.destroy
        else
          prefix = "#{key}-"
          @@fonts.reject! do |k, font|
            if k.starts_with?(prefix)
              font.destroy
              true
            else
              false
            end
          end
        end

        if @@font_data.has_key?(key)
          @@font_data.delete(key)
        end
      end
    end

    def self.clear_all : Nil
      @@mutex.synchronize do
        # Close all unique fonts
        @@fonts.values.uniq.each do |font|
          font.destroy
        end

        @@fonts.clear

        # Close all unique fonts from the weak cache
        @@cache.each_value do |weak_ref|
          if font = weak_ref.value
            font.destroy
          end
        end
        @@cache.clear
        @@registry.clear

        @@font_data.clear
        @@families.clear
      end
    end

    def self.begin_frame : Nil
      @@mutex.synchronize do
        @@fonts.each_value &.begin_frame

        # Touch frames for all cached fonts as well
        @@cache.each_value do |weak_ref|
          if font = weak_ref.value
            font.begin_frame
          end
        end
      end
    end

    @[AlwaysInline]
    private def self.get_key(name : String, size : Num, outline : Int32) : String
      "#{name}-#{size}-#{outline}"
    end

    private def self.get_name(path : String)
      ext = File.extname(path)
      File.basename(path, ext)
    end

    private def self.load_font_data_unlocked(path_key : String) : Nil
      resolved_name = get_name(path_key)
      return if @@font_data.has_key?(resolved_name)

      begin
        data = {% if flag?(:release) %}
          manifest_key = path_key.starts_with?("assets/") ? path_key.sub("assets/", "") : path_key
          AssetManager.load_raw_data(manifest_key)
        {% else %}
          full_path = if path_key.starts_with?("assets/") || path_key.starts_with?(GSDL::AssetManager.asset_path)
            path_key
          else
            GSDL::AssetManager.asset_path + path_key
          end
          File.open(full_path) do |file|
            slice = Bytes.new(file.size.to_i)
            file.read_fully(slice)
            slice
          end
        {% end %}
        @@font_data[resolved_name] = data
      rescue ex
        raise "Failed to dynamically load font file at '#{path_key}': #{ex.message}"
      end
    end

    def self.find_symbol(name : String) : Symbol?
      @@mutex.synchronize do
        clean_name = name.downcase.gsub('-', '_').gsub('_', "")
        @@registry.each_key do |sym|
          if sym.to_s.downcase.gsub('_', "") == clean_name
            return sym
          end
        end
      end
      nil
    end

    def self.register_pair(key : Symbol, val : String)
      @@mutex.synchronize do
        path = val.starts_with?("assets/fonts/") ? val : "assets/fonts/#{val}"
        @@registry[key] = path
      end
    end

    def self.register_runtime(mappings : Hash(Symbol, String))
      mappings.each do |key, val|
        register_pair(key, val)
      end
    end

    def self.register_runtime(mappings : NamedTuple)
      mappings.each do |key, val|
        register_pair(key, val.to_s)
      end
    end

    macro register(mappings)
      {% if mappings.is_a?(HashLiteral) || mappings.is_a?(NamedTupleLiteral) %}
        {% for key, val in mappings %}
          ::GSDL::FontManager.register_pair(:{{key.id}}, {{val}})
        {% end %}
      {% else %}
        ::GSDL::FontManager.register_runtime({{mappings}})
      {% end %}
    end
  end
end
