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
    @last_tick : UInt64 = 0_i64
    @exit : Bool = false
    @title : String?
    @width : Int32?
    @height : Int32?

    def window; @window.not_nil!; end
    def scene_manager; @scene_manager.not_nil!; end
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

    def init
      {% if flag?(:release) %}
        AssetManager.load_pack
      {% end %}

      TextureManager.setup(Game.draw_instance)
      FontManager.setup
      AudioManager.setup
      TileMapManager.setup

      TextBase.draw = Game.draw_instance

      load_textures
      load_fonts
      load_audio
      load_tile_maps

      {% if flag?(:release) %}
        AssetManager.close_pack
      {% end %}
    end

    def load_textures
    end

    def load_fonts
    end

    def load_audio
    end

    def load_tile_maps
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
      init

      @exit = false
      @last_tick = GSDL.ticks

      while !exit?
        InputEvents.update

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
