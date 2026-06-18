module GSDL
  module FontManager
    DefaultFontKey = :default
    DefaultFontSize = 16_f32
    DefaultOutline = 0

    @@fonts : Hash(String, Font)? = nil
    @@font_data : Hash(String, Bytes)? = nil
    @@families : Hash(String, FontFamily)? = nil
    @@registry : Hash(Symbol, String)? = nil
    @@cache : Hash(Tuple(Symbol, Float32, Int32, FontWeight, FontStyle), WeakRef(Font))? = nil
    @@mutex : Mutex? = nil
    @@default = DefaultFontKey

    # 2. Add safe, type-narrowed getters for internal engine methods to use
    private def self.fonts; @@fonts.not_nil!; end
    private def self.font_data; @@font_data.not_nil!; end
    private def self.families; @@families.not_nil!; end
    private def self.registry; @@registry.not_nil!; end
    private def self.cache; @@cache.not_nil!; end
    private def self.mutex; @@mutex.not_nil!; end

    def self.setup
      # guard against double-initialization
      return if @@mutex

      # allocate everything cleanly on the active thread stack
      fonts = Hash(String, Font).new
      font_data = Hash(String, Bytes).new
      families = Hash(String, FontFamily).new
      registry = Hash(Symbol, String).new
      cache = Hash(Tuple(Symbol, Float32, Int32, FontWeight, FontStyle), WeakRef(Font)).new
      mutex = Mutex.new

      # assign them back to the module variables
      @@fonts = fonts
      @@font_data = font_data
      @@families = families
      @@registry = registry
      @@cache = cache
      @@mutex = mutex
    end

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
      self.mutex.synchronize do
        self.families[name] = family
      end
    end

    def self.load_default(path_key : String, size : Float32 = DefaultFontSize, outline = DefaultOutline)
      @@default = :default
      register_pair(:default, path_key)
      load(path_key, size, outline)
    end

    # Loads a font based on the mode (release/debug).
    def self.load(path_key : String, size : Num, outline : Int32) : Font
      self.mutex.synchronize do
        font_key = get_key(get_name(path_key), size, outline)

        if self.fonts.has_key?(font_key)
          return self.fonts[font_key]
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

          GSDL::FS.read_asset(full_path)
        {% end %}

        name = get_name(path_key)
        self.font_data[name] = data

        font = Font.new(name: name, data: data, size: size, outline: outline)
        self.fonts[font_key] = font
        font
      end
    end

    def self.load_from_memory(name : String, data : Bytes, size : Num, outline : Int32) : Font
      self.mutex.synchronize do
        font_key = get_key(name, size, outline)
        if self.fonts.has_key?(font_key)
          return self.fonts[font_key]
        end

        self.font_data[name] = data

        font = Font.new(name: name, data: data, size: size, outline: outline)
        self.fonts[font_key] = font
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
      self.mutex.synchronize do
        cache_key = {id, size.to_f32, outline, weight, style}
        if weak_ref = self.cache[cache_key]?
          if font = weak_ref.value
            return font
          end
        end

        path_key = self.registry[id]?
        if path_key.nil?
          if id == :default && (default_sym = @@default) != :default
            path_key = self.registry[default_sym]?
          elsif self.families.has_key?(id.to_s)
            path_key = id.to_s
          else
            clean_sym = id.to_s.downcase.gsub('_', "").gsub('-', "")
            if matched_family = self.families.keys.find { |fam| fam.downcase.gsub('_', "").gsub('-', "") == clean_sym }
              path_key = matched_family
            end
          end
        end

        if path_key
          resolved_name = get_name(path_key)
          font_key = get_key(resolved_name, size, outline)
          if font = self.fonts[font_key]?
            return font
          end
        else
          font_key = get_key(id.to_s, size, outline)
          if font = self.fonts[font_key]?
            return font
          end

          # Also check by name (without extension) if id.to_s matches
          self.fonts.each_key do |fkey|
            if fkey.starts_with?("#{id.to_s}-")
              if font = self.fonts[fkey]?
                return font
              end
            end
          end

          raise "Asset Registry Error: Symbol :#{id} was never registered!"
        end

        if family = self.families[path_key]?
          resolved_path = family.resolve(weight, style)
        else
          resolved_path = path_key
        end

        resolved_name = get_name(resolved_path)

        unless self.font_data.has_key?(resolved_name)
          load_font_data_unlocked(resolved_path)
        end

        if data = self.font_data[resolved_name]?
          font = Font.new(name: resolved_name, data: data, size: size, outline: outline)
          self.cache[cache_key] = WeakRef.new(font)
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
      self.mutex.synchronize do
        if family = self.families[name]?
          path_key = family.resolve(weight, style)
        else
          path_key = name
        end

        resolved_name = get_name(path_key)
        font_key = get_key(resolved_name, size, outline)

        if font = self.fonts[font_key]?
          return font
        end

        unless self.font_data.has_key?(resolved_name)
          load_font_data_unlocked(path_key)
        end

        if data = self.font_data[resolved_name]?
          font = Font.new(name: resolved_name, data: data, size: size, outline: outline)
          self.fonts[font_key] = font
          return font
        end

        raise "Font with name '#{resolved_name}' (derived from '#{name}' with weight: #{weight}, style: #{style}) not found and dynamic loading failed."
      end
    end

    # Housekeeping Maintenance Pass (Call during scene transitions)
    def self.prune_dead_references : Nil
      self.mutex.synchronize do
        self.cache.select! do |key, weak_ref|
          !weak_ref.value.nil?
        end
      end
    end

    def self.unload(key : String) : Nil
      self.mutex.synchronize do
        if font = self.fonts.delete(key)
          font.destroy
        else
          prefix = "#{key}-"
          self.fonts.reject! do |k, font|
            if k.starts_with?(prefix)
              font.destroy
              true
            else
              false
            end
          end
        end

        if self.font_data.has_key?(key)
          self.font_data.delete(key)
        end
      end
    end

    def self.clear_all : Nil
      self.mutex.synchronize do
        # Close all unique fonts
        self.fonts.values.uniq.each do |font|
          font.destroy
        end

        self.fonts.clear

        # Close all unique fonts from the weak cache
        self.cache.each_value do |weak_ref|
          if font = weak_ref.value
            font.destroy
          end
        end
        self.cache.clear
        self.registry.clear

        self.font_data.clear
        self.families.clear
      end
    end

    def self.begin_frame : Nil
      self.mutex.synchronize do
        self.fonts.each_value &.begin_frame

        # Touch frames for all cached fonts as well
        self.cache.each_value do |weak_ref|
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
      return if self.font_data.has_key?(resolved_name)

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

          GSDL::FS.read_asset(full_path)
        {% end %}
        self.font_data[resolved_name] = data
      rescue ex
        raise "Failed to dynamically load font file at '#{path_key}': #{ex.message}"
      end
    end

    def self.find_symbol(name : String) : Symbol?
      self.mutex.synchronize do
        clean_name = name.downcase.gsub('-', '_').gsub('_', "")
        self.registry.each_key do |sym|
          if sym.to_s.downcase.gsub('_', "") == clean_name
            return sym
          end
        end
      end
      nil
    end

    def self.register_pair(key : Symbol, val : String)
      self.mutex.synchronize do
        path = val.starts_with?("assets/fonts/") ? val : "assets/fonts/#{val}"
        self.registry[key] = path
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
