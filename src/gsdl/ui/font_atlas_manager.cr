module GSDL
  module FontAtlasManager
    DefaultFontKey = "default"
    DefaultFontSize = 16_f32
    DefaultOutline = 0

    # key: #{name}-#{font_size}-#{outline}
    @@fonts = Hash(String, FontAtlas).new
    @@mutex = Mutex.new

    def self.default
      DefaultFontKey
    end

    def self.default_size
      DefaultFontSize
    end

    def self.default_outline
      DefaultOutline
    end

    # Loads a font atlas based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending AssetManager.asset_path.
    def self.load(key : String, path_key : String, size : Float32, outline : Int32) : FontAtlas
      @@mutex.synchronize do
        font_key = full_key(key, size, outline)

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

        font = FontAtlas.new(data: data, size: size, outline: outline)
        @@fonts[font_key] = font
        font
      end
    end

    def self.load_from_memory(key : String, data : Bytes, size : Float32, outline : Int32) : FontAtlas
      @@mutex.synchronize do
        font_key = full_key(key, size, outline)
        if @@fonts.has_key?(font_key)
          return @@fonts[font_key]
        end

        font = FontAtlas.new(data: data, size: size, outline: outline)
        @@fonts[font_key] = font
        font
      end
    end

    def self.get(key : String, size : Float32, outline : Int32) : FontAtlas
      @@mutex.synchronize do
        font_key = full_key(key, size, outline)
        @@fonts[font_key]? || raise "FontAlas with key '#{key}' (and size #{size}, outline #{outline}) not found in FontAtlasManager. Was it loaded?"
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
      end
    end

    def self.clear_all : Nil
      @@mutex.synchronize do
        # Close all unique fonts
        @@fonts.values.uniq.each do |font|
          font.destroy
        end

        @@fonts.clear
      end
    end

    @[AlwaysInline]
    private def self.full_key(key : String, size : Float32, outline : Int32) : String
      "#{key}-#{size}-#{outline}"
    end
  end
end
