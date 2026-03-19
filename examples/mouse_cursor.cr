require "../src/game_sdl"

module GameEx
  alias Mouse = GSDL::Mouse
  alias Text = GSDL::Text
  alias Cursor = GSDL::Cursor

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Mouse Cursor Ex", width: WIDTH, height: HEIGHT)
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(CursorScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class CursorScene < GSDL::Scene
    @text : Text
    @default_cursor : Cursor?
    @crosshair_cursor : Cursor
    @coin_cursor : Cursor
    @tile_cursor : Cursor

    def initialize
      super(:cursor)
      color = GSDL::Color.new(r: 255, g: 255, b: 255, a: 255)
      @text = Text.new(
        text: "1: Default, 2: Crosshair, 3: Coin, 4: Tile",
        origin: {0.5_f32, 0.5_f32},
        color: color
      )
      @text.center(width: WIDTH, height: HEIGHT)

      # Get current cursor to be able to restore it if needed,
      # but SDL3::Mouse.get_cursor returns an SDL3::Mouse::Cursor, we wrap it
      if sdl_cursor = SDL3::Mouse.get_cursor
        @default_cursor = Cursor.new(sdl_cursor)
      end

      @crosshair_cursor = Cursor.create_system(LibSDL3::SystemCursor::CROSSHAIR)
      @coin_cursor = Cursor.load("gfx/coin.png", centered: true)
      @tile_cursor = Cursor.load("gfx/tiles.png", hot_x: 0, hot_y: 0, source_rect: GSDL::Rect.new(x: 0, y: 0, w: 32, h: 32))
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::One)
        if cur = @default_cursor
          Mouse.cursor = cur
        end
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Two)
        Mouse.cursor = @crosshair_cursor
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Three)
        Mouse.cursor = @coin_cursor
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Four)
        Mouse.cursor = @tile_cursor
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
    end
  end

  Game.new.run
end
