module GSDL
  module FontManager
    DefaultFontKey = "default"
    DefaultFontSize = 16_f32
    DefaultOutline = 0

    # key: #{name}-#{font_size}-#{outline}
    @@fonts = Hash(String, Font).new
    @@font_data = Hash(String, Bytes).new
    @@mutex = Mutex.new
    @@default = DefaultFontKey

    def self.default
      @@default
    end

    def self.default_size
      DefaultFontSize
    end

    def self.default_outline
      DefaultOutline
    end

    def self.load_default(path_key : String, size : Float32 = DefaultFontSize, outline = DefaultOutline)
      @@default = get_name(path_key)
      load(path_key, size, outline)
    end

    # Loads a font based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending AssetManager.asset_path.
    def self.load(path_key : String, size : Num, outline : Int32) : Font
      @@mutex.synchronize do
        font_key = get_key(get_name(path_key), size, outline)

        if @@fonts.has_key?(font_key)
          return @@fonts[font_key]
        end

        # see TextureManager.load comments for more details on path_key
        # which is a key based on the path like 'fonts/PressStart2P.ttf'
        # and will either load from the asset.pack file in release mode
        # or from the 'assets/fonts/PressStart2P.ttf' file directly in debug mode

        # Using flag?(:release) for compile-time conditional compilation.
        # When compiling with `crystal build --release`, the :release flag is set.
        data = {% if flag?(:release) %}
          # In release mode, defer to AssetManager which handles packfile loading
          # NOTE: we use `load_raw_data` instead of usual `with_io_stream` because we do
          # not need an SDL3::IOStream object that needs to stay "open" since we get raw Bytes
          AssetManager.load_raw_data(path_key)
        {% else %}
          # In debug mode, load from loose files, make sure we allocate a new slice via Bytes.new
          # instead of reusing a File.read / File.read_all string pointer with String#to_slice
          File.open(AssetManager.asset_path + path_key) do |file|
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

    def self.get(name : String, size : Num, outline : Int32) : Font
      @@mutex.synchronize do
        font_key = get_key(name, size, outline)
        if font = @@fonts[font_key]?
          return font
        end

        if data = @@font_data[name]?
          font = Font.new(name: name, data: data, size: size, outline: outline)
          @@fonts[font_key] = font
          return font
        end

        raise "Font with name '#{name}' (and size #{size}, outline #{outline}) not found in FontManager and raw font data is unavailable."
      end
    end

    def self.unload(key : String) : Nil
      @@mutex.synchronize do
        # This unloads ALL sizes for this key if it's a name key,
        # or just the specific size if it's a compound key
        if font = @@fonts.delete(key)
          font.destroy
        else
          # delete any size / outline variants
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
        @@font_data.clear
      end
    end

    def self.begin_frame : Nil
      @@mutex.synchronize do
        @@fonts.each_value &.begin_frame
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
  end
end
