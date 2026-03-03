module GSDL
  class Cursor
    @internal : SDL3::Mouse::Cursor

    def self.create_system(id : LibSDL3::SystemCursor) : Cursor
      new(SDL3::Mouse::Cursor.create_system(id))
    end

    def self.create_from_surface(surface : Surface, hot_x : Int32 = 0, hot_y : Int32 = 0) : Cursor
      new(SDL3::Mouse::Cursor.create_color(surface.to_sdl, hot_x, hot_y))
    end

    def self.load(path_key : String, hot_x : Int32 = 0, hot_y : Int32 = 0) : Cursor
      {% if flag?(:release) %}
        AssetManager.with_io_stream(path_key) do |io_stream|
          surface_sdl = SDL3::Image.load_io(io_stream, close_io: true)
          create_from_surface(Surface.new(surface_sdl), hot_x, hot_y)
        end
      {% else %}
        full_path = GSDL::AssetManager.asset_path + path_key
        surface_sdl = SDL3::Image.load(full_path)
        create_from_surface(Surface.new(surface_sdl), hot_x, hot_y)
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
