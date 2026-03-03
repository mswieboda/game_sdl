module GSDL
  class Cursor
    @internal : SDL3::Mouse::Cursor

    def self.create_system(id : LibSDL3::SystemCursor) : Cursor
      new(SDL3::Mouse::Cursor.create_system(id))
    end

    def self.create_from_surface(surface : Surface, hot_x : Int32 = 0, hot_y : Int32 = 0, source_rect : Rect? = nil, centered : Bool = false) : Cursor
      hx = hot_x
      hy = hot_y

      if rect = source_rect
        temp_surface = Surface.new(width: rect.w, height: rect.h, format: surface.to_sdl.format)
        surface.to_sdl.blit(rect.to_sdl, nil, temp_surface.to_sdl)

        if centered
          hx = temp_surface.w // 2
          hy = temp_surface.h // 2
        end

        cursor = new(SDL3::Mouse::Cursor.create_color(temp_surface.to_sdl, hx, hy))
        temp_surface.destroy
        cursor
      else
        if centered
          hx = surface.w // 2
          hy = surface.h // 2
        end

        new(SDL3::Mouse::Cursor.create_color(surface.to_sdl, hx, hy))
      end
    end

    def self.load(path_key : String, hot_x : Int32 = 0, hot_y : Int32 = 0, source_rect : Rect? = nil, centered : Bool = false) : Cursor
      {% if flag?(:release) %}
        AssetManager.with_io_stream(path_key) do |io_stream|
          surface_sdl = SDL3::Image.load_io(io_stream, close_io: true)
          create_from_surface(Surface.new(surface_sdl), hot_x, hot_y, source_rect, centered)
        end
      {% else %}
        full_path = GSDL::AssetManager.asset_path + path_key
        surface_sdl = SDL3::Image.load(full_path)
        create_from_surface(Surface.new(surface_sdl), hot_x, hot_y, source_rect, centered)
      {% end %}
    end

    def initialize(cursor : SDL3::Mouse::Cursor)
      @internal = cursor
    end

    def destroy
      @internal.destroy
    end

    def to_sdl
      @internal
    end
  end
end
