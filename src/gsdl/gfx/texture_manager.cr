module GSDL
  module TextureManager
    @@textures = Hash(String, Texture).new
    @@atlases = [] of Texture
    @@registry = Hash(Symbol, String).new
    @@cache = Hash(Symbol, WeakRef(Texture)).new
    @@mutex = Mutex.new

    def self.finalize_atlas
      @@mutex.synchronize do
        # Gather all active texture references held by the current scene from the WeakRef cache
        to_pack = [] of Texture
        @@cache.each_value do |weak_ref|
          if tex = weak_ref.value
            # Only pack if it hasn't already been assigned to an atlas page
            to_pack << tex if tex.atlas_handle.nil?
          end
        end

        to_pack.uniq!
        return if to_pack.empty?

        # Sort by height descending (Preserve existing shelf-packing logic)
        to_pack.sort_by! { |t| -t.height }

        max_size = Game.draw.to_sdl.properties.get_number(LibSDL3::SDL_PROP_RENDERER_MAX_TEXTURE_SIZE_NUMBER).to_i
        padding = 2

        current_atlas_w = 512
        current_atlas_h = 512

        # Determine initial POT size that can fit the largest item
        while current_atlas_w < to_pack.first.width + padding * 2 || current_atlas_h < to_pack.first.height + padding * 2
          if current_atlas_w <= current_atlas_h
            current_atlas_w *= 2
          else
            current_atlas_h *= 2
          end
        end

        pages = [] of Array(Tuple(Texture, Int32, Int32))

        loop do
          current_page = [] of Tuple(Texture, Int32, Int32)
          remaining = [] of Texture

          shelf_x = padding
          shelf_y = padding
          shelf_h = 0

          to_pack.each do |tex|
            tw = tex.width.to_i + padding * 2
            th = tex.height.to_i + padding * 2

            if shelf_x + tw > current_atlas_w
              shelf_x = padding
              shelf_y += shelf_h
              shelf_h = 0
            end

            if shelf_y + th > current_atlas_h
              # Won't fit in current atlas size
              remaining << tex
              next
            end

            current_page << {tex, shelf_x, shelf_y}
            shelf_x += tw
            shelf_h = Math.max(shelf_h, th)
          end

          if remaining.empty?
            pages << current_page
            break
          elsif pages.empty? && (current_atlas_w < max_size || current_atlas_h < max_size)
            # Try growing the atlas if we haven't committed any pages yet
            if current_atlas_w <= current_atlas_h
              current_atlas_w *= 2
            else
              current_atlas_h *= 2
            end
            next
          else
            # Commit current page and try to pack remaining into new pages
            pages << current_page
            to_pack = remaining
            # Reset dimensions for next pages (could optimize to keep large, but start small)
            # Actually better to keep the size we found for subsequent pages
          end
        end

        # Render atlases
        pages.each do |page|
          atlas_tex = Texture.new(current_atlas_w, current_atlas_h, access: TextureAccess::Target)
          Game.draw.with_target(atlas_tex) do
            Game.draw.color = Color::Transparent
            Game.draw.clear

            page.each do |(tex, x, y)|
              # Draw sub-texture into atlas
              # We use draw_immediately to avoid recursive push_cmd issues
              Game.draw.texture(tex, x: x.to_f32, y: y.to_f32, draw_immediately: true)

              # Set atlas metadata
              tex.atlas_handle = atlas_tex.to_sdl
              tex.atlas_rect = FRect.new(x: x.to_f32, y: y.to_f32, w: tex.width, h: tex.height)
            end
          end

          @@atlases << atlas_tex
        end
      end
    end

    def self.preload(symbols : Array(Symbol)) : Nil
      @@mutex.synchronize do
        symbols.each do |sym|
          get_internal(sym)
        end
      end
    end

    # Safe, Lazy-Loading Fetch Pass for Symbol keys
    def self.get(id : Symbol) : Texture
      @@mutex.synchronize do
        get_internal(id)
      end
    end

    private def self.get_internal(id : Symbol) : Texture
      if weak_ref = @@cache[id]?
        if texture = weak_ref.value
          return texture
        end
      end

      # Check legacy loaded textures
      if texture = @@textures[id.to_s]?
        return texture
      end

      path = @@registry[id]? || raise "Asset Registry Error: Symbol :#{id} was never registered!"
      texture = load_raw_texture(path)
      @@cache[id] = WeakRef.new(texture)
      texture
    end

    # Housekeeping Maintenance Pass (Call during scene transitions)
    def self.prune_dead_references : Nil
      @@mutex.synchronize do
        @@cache.select! do |key, weak_ref|
          !weak_ref.value.nil?
        end
      end
    end

    # Loads a texture based on the mode (release/debug).
    def self.load(key : String, path_key : String) : Texture
      @@mutex.synchronize do
        if @@textures.has_key?(key)
          return @@textures[key]
        end

        texture = load_raw_texture(path_key)
        @@textures[key] = texture
        texture
      end
    end

    private def self.load_raw_texture(path_key : String) : Texture
      {% if flag?(:release) %}
        # In release mode, use AssetManager to load from the packfile.
        manifest_key = path_key.starts_with?("assets/") ? path_key.sub("assets/", "") : path_key
        AssetManager.with_io_stream(manifest_key) do |io_stream|
          texture_sdl = SDL3::Image.load_texture_io(Game.draw.to_sdl, io_stream, close_io: true)
          Texture.new(texture_sdl)
        end
      {% else %}
        # In debug mode, load from loose files
        full_path = if path_key.starts_with?("assets/") || path_key.starts_with?(GSDL::AssetManager.asset_path)
          path_key
        else
          GSDL::AssetManager.asset_path + path_key
        end
        texture_sdl = SDL3::Image.load_texture(Game.draw.to_sdl, full_path)
        Texture.new(texture_sdl)
      {% end %}
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
        path = val.starts_with?("assets/gfx/") ? val : "assets/gfx/#{val}"
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
          ::GSDL::TextureManager.register_pair(:{{key.id}}, {{val}})
        {% end %}
      {% else %}
        ::GSDL::TextureManager.register_runtime({{mappings}})
      {% end %}
    end

    # Loads a texture from raw byte data and associates it with a key.
    def self.load_from_memory(key : String, io : SDL3::IOStream) : Texture
      @@mutex.synchronize do
        if @@textures.has_key?(key)
          return @@textures[key]
        end
        texture_sdl = SDL3::Image.load_texture_io(Game.draw.to_sdl, io, close_io: true)
        texture = Texture.new(texture_sdl)
        @@textures[key] = texture
        texture
      end
    end

    # Loads a texture from an SDL surface and associates it with a key.
    def self.load_from_surface(key : String, surface : Surface) : Texture
      @@mutex.synchronize do
        if @@textures.has_key?(key)
          return @@textures[key]
        end
        texture_sdl = SDL3::Texture.from_surface(Game.draw.to_sdl, surface.to_sdl)
        texture = Texture.new(texture_sdl)
        @@textures[key] = texture
        texture
      end
    end

    # Retrieves a loaded texture by its key.
    def self.get(key : String) : Texture
      @@mutex.synchronize do
        if @@textures.has_key?(key)
          return @@textures[key]
        end
      end

      raise "Texture with key '#{key}' not found in TextureManager. Was it loaded?"
    end

    # Unloads a specific texture from memory.
    def self.unload(key : String) : Nil
      @@mutex.synchronize do
        if texture = @@textures.delete(key)
          texture.destroy
        end
      end
    end

    # Unloads all managed textures from memory.
    def self.clear_all : Nil
      @@mutex.synchronize do
        @@textures.each_value &.destroy
        @@textures.clear

        @@cache.each_value do |weak_ref|
          if t = weak_ref.value
            t.destroy
          end
        end
        @@cache.clear
        @@registry.clear

        @@atlases.each &.destroy
        @@atlases.clear
      end
    end
  end
end
