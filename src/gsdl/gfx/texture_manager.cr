module GSDL
  class TextureManager
    @@instance : TextureManager = new
    @textures : Hash(String, Texture)
    @atlases = [] of Texture
    @mutex = Mutex.new

    private def initialize
      @textures = Hash(String, Texture).new
    end

    def self.finalize_atlas
      @@instance.finalize_atlas
    end

    def finalize_atlas
      @mutex.synchronize do
        return if @textures.empty?

        # Gather textures that aren't already part of an atlas
        to_pack = @textures.values.select { |t| t.atlas_handle.nil? }.sort_by { |t| -t.height }
        return if to_pack.empty?

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
          
          @atlases << atlas_tex
        end
      end
    end

    # Loads a texture based on the mode (release/debug).
    # In release mode, it uses AssetManager to load from the packfile.
    # In debug mode, it loads from the loose asset filesystem path,
    # prepending GSDL::AssetManager.asset_path.
    def self.load(key : String, path_key : String) : Texture
      # NOTE: In release builds, 'path_key' refers to the key in the asset pack.
      # In debug builds, 'path_key' refers to the relative path within @@asset_path.
      # example path_key in both cases: 'gfx/skeleton.png'
      # which loads file from 'assets/gfx/skeleton.png' in debug mode, or from
      # key 'gfx/skeleton.png' loading data from the asset.pack file
      # via the AssetManager manifest hash data

      # Using flag?(:release) for compile-time conditional compilation.
      # When compiling with `crystal build --release`, the :release flag is set.
      #
      {% if flag?(:release) %}
        # In release mode, use AssetManager to load from the packfile.
        # The `with_io_stream` method ensures the underlying data stays alive.
        AssetManager.with_io_stream(path_key) do |io_stream|
          load_from_memory(key, io_stream)
        end
      {% else %}
        # In debug mode, load from loose files
        # The `asset_path` is used to resolve the full path in debug mode
        full_path = GSDL::AssetManager.asset_path + path_key
        @@instance.load(key, full_path) # Delegate to the internal instance
      {% end %}
    end

    # Loads a texture from raw byte data and associates it with a key.
    # This method is primarily intended to be called by load if in release mode
    def self.load_from_memory(key : String, io : SDL3::IOStream) : Texture
      @@instance.load_from_memory(key, io)
    end

    # Loads a texture from an SDL surface and associates it with a key.
    def self.load_from_surface(key : String, surface : Surface) : Texture
      @@instance.load_from_surface(key, surface)
    end

    # Retrieves a loaded texture by its key.
    # Returns nil if the texture is not found.
    def self.get(key : String) : Texture
      @@instance.get(key) # Delegate to the internal instance
    end

    # Unloads a specific texture from memory.
    def self.unload(key : String) : Nil
      @@instance.unload(key) # Delegate to the internal instance
    end

    # Unloads all managed textures from memory.
    def self.clear_all : Nil
      @@instance.clear_all # Delegate to the internal instance
    end

    # --- Instance methods (called by class methods via the singleton instance) ---

    def load(key : String, path : String) : Texture
      @mutex.synchronize do
        if @textures.has_key?(key)
          return @textures[key]
        end
        texture_sdl = SDL3::Image.load_texture(Game.draw.to_sdl, path)
        texture = Texture.new(texture_sdl)
        @textures[key] = texture
        texture
      end
    end

    def load_from_memory(key : String, io : SDL3::IOStream) : Texture
      @mutex.synchronize do
        if @textures.has_key?(key)
          return @textures[key]
        end
        texture_sdl = SDL3::Image.load_texture_io(Game.draw.to_sdl, io, close_io: true)
        texture = Texture.new(texture_sdl)
        @textures[key] = texture
        texture
      end
    end

    def load_from_surface(key : String, surface : Surface) : Texture
      @mutex.synchronize do
        if @textures.has_key?(key)
          return @textures[key]
        end
        texture_sdl = SDL3::Texture.from_surface(Game.draw.to_sdl, surface.to_sdl)
        texture = Texture.new(texture_sdl)
        @textures[key] = texture
        texture
      end
    end

    def get(key : String) : Texture
      @mutex.synchronize do
        @textures.fetch(key) do
          raise "Texture with key '#{key}' not found in TextureManager. Was it loaded?"
        end
      end
    end

    def unload(key : String) : Nil
      @mutex.synchronize do
        if texture = @textures.delete(key)
          texture.destroy
        end
      end
    end

    def clear_all : Nil
      @mutex.synchronize do
        @textures.each_value do |texture|
          texture.destroy
        end
        @textures.clear

        @atlases.each do |atlas|
          atlas.destroy
        end
        @atlases.clear
      end
    end
  end
end
