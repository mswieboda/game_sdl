module GSDL
  module TextureManager
    @@draw : Draw? = nil
    @@textures = Hash(String, Texture).new
    @@atlases = [] of Texture
    @@mutex = Mutex.new

    # Sets up the TextureManager with the given Draw.
    # This should be called once at the start of the application.
    def self.setup(draw : Draw)
      @@draw = draw
    end

    private def self.draw : Draw
      @@draw || raise "TextureManager not setup with a Draw instance!"
    end

    def self.finalize_atlas
      @@mutex.synchronize do
        return if @@textures.empty?

        # Gather textures that aren't already part of an atlas
        to_pack = @@textures.values.select { |t| t.atlas_handle.nil? }.sort_by { |t| -t.height }
        return if to_pack.empty?

        max_size = draw.to_sdl.properties.get_number(LibSDL3::SDL_PROP_RENDERER_MAX_TEXTURE_SIZE_NUMBER).to_i
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
          draw.with_target(atlas_tex) do
            draw.color = Color::Transparent
            draw.clear
            
            page.each do |(tex, x, y)|
              # Draw sub-texture into atlas
              # We use draw_immediately to avoid recursive push_cmd issues
              draw.texture(tex, x: x.to_f32, y: y.to_f32, draw_immediately: true)
              
              # Set atlas metadata
              tex.atlas_handle = atlas_tex.to_sdl
              tex.atlas_rect = FRect.new(x: x.to_f32, y: y.to_f32, w: tex.width, h: tex.height)
            end
          end
          
          @@atlases << atlas_tex
        end
      end
    end

    # Loads a texture based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending GSDL::AssetManager.asset_path.
    def self.load(key : String, path_key : String) : Texture
      @@mutex.synchronize do
        if @@textures.has_key?(key)
          return @@textures[key]
        end

        # Using flag?(:release) for compile-time conditional compilation.
        #
        texture = {% if flag?(:release) %}
          # In release mode, use AssetManager to load from the packfile.
          AssetManager.with_io_stream(path_key) do |io_stream|
            texture_sdl = SDL3::Image.load_texture_io(draw.to_sdl, io_stream, close_io: true)
            Texture.new(texture_sdl)
          end
        {% else %}
          # In debug mode, load from loose files
          full_path = GSDL::AssetManager.asset_path + path_key
          texture_sdl = SDL3::Image.load_texture(draw.to_sdl, full_path)
          Texture.new(texture_sdl)
        {% end %}

        @@textures[key] = texture
        texture
      end
    end

    # Loads a texture from raw byte data and associates it with a key.
    def self.load_from_memory(key : String, io : SDL3::IOStream) : Texture
      @@mutex.synchronize do
        if @@textures.has_key?(key)
          return @@textures[key]
        end
        texture_sdl = SDL3::Image.load_texture_io(draw.to_sdl, io, close_io: true)
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
        texture_sdl = SDL3::Texture.from_surface(draw.to_sdl, surface.to_sdl)
        texture = Texture.new(texture_sdl)
        @@textures[key] = texture
        texture
      end
    end

    # Retrieves a loaded texture by its key.
    def self.get(key : String) : Texture
      @@mutex.synchronize do
        @@textures[key]? || raise "Texture with key '#{key}' not found in TextureManager. Was it loaded?"
      end
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

        @@atlases.each &.destroy
        @@atlases.clear
      end
    end
  end
end
