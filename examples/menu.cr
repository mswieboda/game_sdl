require "../src/game_sdl"

module GameEx
  alias Keys = GSDL::Keys
  alias Mouse = GSDL::Mouse
  alias Font = GSDL::Font
  alias Text = GSDL::Text
  alias Menu = GSDL::Menu
  alias Color = GSDL::Color
  alias Box = GSDL::Box
  alias AnimatedSprite = GSDL::AnimatedSprite
  alias FRect = GSDL::FRect
  alias Num = GSDL::Num

  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Menu Ex", width: WIDTH, height: HEIGHT)
    end

    def init
      super
      @scene_manager = SceneManager.new
    end

    def load_textures
      GSDL::TextureManager.load("coin", "gfx/coin.png")
    end

    def load_fonts
      GSDL::FontManager.load_default("fonts/PressStart2P.ttf")
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super

      @scene = MenuScene.new
    end
  end

  class MenuScene < GSDL::Scene
    @menu : Menu
    @message : Text
    @rainbow : Bool = false

    MESSAGE_INFO = "Choose: UP / DOWN\n\nSelect: SPACE / ENTER / L MOUSE BUTTON\n\n TAB for rainbow options"
    RANDOM_COLOR_SEED = rand(999)

    def initialize
      super(:menu)

      @message = Text.new(
        text: MESSAGE_INFO,
        x: WIDTH / 2_f32,
        y: 32,
        origin: {0.5_f32, 0_f32},
        align: Font::Align::Center
      )


      # this helper outputs (since the strings are same as the symbols):
      # [
      #   {:start, "start"},
      #   {:options, "options"},
      #   {:extra, "extra"},
      #   {:credits, "credits"}
      #   {:exit, "exit"}
      # ]
      # which is the `items:` param format Tuple(Symbol, String)
      items = [:continue, :new, :extra, :options, :credits, :help, :exit].map do |key|
        {key, key.to_s}
      end


      on_select = ->(id : Symbol) {
        @message.text = MESSAGE_INFO + "\n\n\n\nSelected: #{id}"
        nil
      }

      icon = AnimatedSprite.new(
        key: "coin",
        width: 32,
        height: 32,
        scale: {0.5_f32, 0.5_f32}
      )
      icon.add("idle", [0, 1, 2, 3, 4, 3, 2, 1], 8, loops: true)
      icon.play("idle")

      @menu = Menu.new(
        is_selected: ->(x : Num, y : Num, w : Num, h : Num) {
          Keys.just_pressed?([Keys::Space, Keys::Return]) ||
            Mouse.clicked_in?(x, y, w, h)
        },
        is_next: -> { Keys.just_pressed?([Keys::S, Keys::Down]) },
        is_previous: -> { Keys.just_pressed?([Keys::W, Keys::Up]) },
        items: items,
        x: WIDTH // 2,
        y: HEIGHT // 2 + 64,
        origin: {0.5_f32, 0.5_f32},
        on_select: on_select,
        text_color: ->(index : Int32) { @rainbow ? rainbow_color(index) : Color::White },
        selected_text_color: ->(index : Int32) { Color::Cyan },
        background_box: Box.new(color: Color::DarkGray, border_radius: 16),
        selected_box: Box.new(color: Color::Gray, border_radius: 8),
        selected_icon: icon,
        selected_icon_placement: Menu::IconPlacement::Both,
        padding: 16,
        separation: 4,
        item_padding: 8,
        items_disabled: [:extra],
        mouse_hover: true,
        hover_text_color: Color::White,
        hover_box: Box.new(color: Color::Silver, border_radius: 8),
      )
    end

    def rainbow_color(index : Int32)
      GSDL::Palettes::Rainbow[index]
    end

    def update(dt : Float32)
      @rainbow = !@rainbow if Keys.just_pressed?(Keys::Tab)

      @menu.update(dt)
      @message.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @menu.draw(draw)
      @message.draw(draw)
    end
  end

  Game.new.run
end

