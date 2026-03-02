module GSDL
  module Global
    @@game : Game?
    @@draw : Draw?

    def self.game : Game
      if game = @@game
        game
      else
        raise "Failed to get global Game instance. Make sure Game.new has been called."
      end
    end

    def self.game=(game : Game)
      @@game = game
    end

    def self.draw : Draw
      if draw = @@draw
        draw
      else
        raise "Failed to get global draw"
      end
    end

    def self.draw=(draw : Draw)
      @@draw = draw
    end
  end

  def self.ticks
    SDL3.get_ticks
  end

  abstract class Game
    DefaultBackgroundColor = Color::Black

    def self.instance : Game
      Global.game
    end

    def self.width : Int32
      Global.game.width
    end

    def self.height : Int32
      Global.game.height
    end

    def self.title : String
      Global.game.title
    end

    def self.draw_instance : Draw
      Global.draw
    end

    @window : SDL3::Window?
    @scene_manager : SceneManager?
    @draw : Draw?
    @loader : Loader?
    @last_tick : UInt64 = 0_i64
    @exit : Bool = false
    @title : String?
    @width : Int32?
    @height : Int32?

    def window; @window.not_nil!; end
    def scene_manager; @scene_manager.not_nil!; end
    def loader; @loader ||= Loader.new; end
    def exit?; @exit; end
    def title; @title.not_nil!; end
    def width; @width.not_nil!; end
    def height; @height.not_nil!; end

    def initialize(title = "", width = 1920, height = 1080)
      @title = title
      @width = width
      @height = height
      
      Global.game = self
      
      SDL3.init
      SDL3::TTF.init
      SDL3::Mixer.init

      @window = SDL3::Window.new(
        title,
        width,
        height,
        flags: 32_u64
      )

      @draw = Draw.new(@window.not_nil!)
      Global.draw = @draw.not_nil!

      TextBase.draw = @draw.not_nil!

      @scene_manager = SceneManager.new
    end

    private def _init
      {% if flag?(:release) %}
        AssetManager.load_pack
      {% end %}

      TextureManager.setup(Game.draw_instance)
      FontManager.setup
      AudioManager.setup
      TileMapManager.setup

      TextBase.draw = Game.draw_instance

      load_assets

      {% if flag?(:release) %}
        AssetManager.close_pack
      {% end %}
    end

    private def load_assets
      # fonts
      default_font_path_key = load_default_font

      unless default_font_path_key.empty?
        FontManager.load_default(path: default_font_path_key)
      end

      font_data_data = load_fonts
      font_data_data.each do |key, path_key, size|
        FontManager.load(key: key, path_key: path_key, size: size)
      end

      # textures
      texture_load_data = load_textures
      texture_load_data.each do |key, path_key|
        TextureManager.load(key: key, path_key: path_key)
      end

      # audio
      audio_load_data = load_audio
      audio_load_data.each do |key, path_key|
        AudioManager.load(key: key, path_key: path_key)
      end

      # tile maps
      tile_map_load_data = load_tile_maps
      tile_map_load_data.each do |key, path_key|
        TileMapManager.load(key: key, path_key: path_key)
      end
    end

    def load_default_font : String
      ""
    end

    def load_fonts : Array(Tuple(String, String, Float32))
      [] of Tuple(String, String, Float32)
    end

    def load_textures : Array(Tuple(String, String))
      [] of Tuple(String, String)
    end

    def load_audio : Array(Tuple(String, String))
      [] of Tuple(String, String)
    end

    def load_tile_maps : Array(Tuple(String, String))
      [] of Tuple(String, String)
    end

    def vsync
      true
    end

    def joystick_threshold
      1.0
    end

    def mouse_cursor_visible
      true
    end

    def background_color
      DefaultBackgroundColor
    end

    def run
      _init
      init

      @exit = false
      @last_tick = GSDL.ticks

      while !exit?
        InputEvents.update
        loader.update

        current_tick = GSDL.ticks
        delta_time_ms = current_tick - @last_tick
        @last_tick = current_tick
        delta_time = delta_time_ms / 1000.0f32

        Events.handle_events

        break if Events.exit? || exit?

        update(delta_time)
        clear_screen
        draw
      end

      destroy
    end

    def update(dt : Float32)
      scene_manager.update(dt)
      @exit = true if scene_manager.exit?
    end

    def clear_screen
      Game.draw_instance.color = background_color
      Game.draw_instance.clear
    end

    def draw
      scene_manager.draw(Game.draw_instance)
      Game.draw_instance.draw
    end

    def destroy
      TextureManager.clear_all
      FontManager.clear_all
      AudioManager.clear_all
      TileMapManager.clear_all
      Game.draw_instance.destroy
      window.destroy
      SDL3.quit
    end
  end
end
