require "../src/game_sdl"

module GameEx
  class Game < GSDL::Game
    def initialize
      super(title: "Font Family Registry & Fallbacks Example")
    end

    def init
      GSDL::Events.esc_exits = true

      # 1. Register a custom font family mapping various weights and styles
      # to different physical files to clearly demonstrate trait-to-file routing
      GSDL::FontManager.register_family("CustomFamily") do |family|
        family.add(GSDL::FontWeight::Normal, GSDL::FontStyle::Regular, "fonts/Roboto-Regular.ttf")
        family.add(GSDL::FontWeight::Bold, GSDL::FontStyle::Regular, "fonts/Electrolize-Regular.ttf")
        family.add(GSDL::FontWeight::Normal, GSDL::FontStyle::Italic, "fonts/PressStart2P.ttf")
      end

      GSDL::Game.push(FontFamilyScene.new)
    end

    def load_default_font
      "fonts/Roboto-Regular.ttf"
    end

    def load_fonts
      [
        {"fonts/Roboto-Regular.ttf", 24, 0},
        {"fonts/Electrolize-Regular.ttf", 24, 0},
        {"fonts/PressStart2P.ttf", 24, 0},
      ]
    end
  end

  class FontFamilyScene < GSDL::Scene
    @texts : Array(GSDL::Text)
    @dynamic_text : GSDL::Text
    @timer : Float32

    def initialize
      super(:font_family)
      @texts = [] of GSDL::Text
      @timer = 0_f32

      x = Game.width / 2_f32
      origin = {0.5_f32, 0.5_f32}

      # Standard header
      @texts << GSDL::Text.new(
        text: "GSDL::FontFamily Typography Registry",
        y: 60,
        x: x,
        origin: origin,
        font_size: 28,
        color: GSDL::Color.new(200, 230, 255)
      )

      # Normal / Regular variant (Roboto-Regular)
      @texts << GSDL::Text.new(
        font: "CustomFamily",
        font_size: 20,
        text: "CustomFamily - Normal / Regular (Resolves to Roboto)",
        y: 160,
        x: x,
        origin: origin,
        weight: GSDL::FontWeight::Normal,
        style: GSDL::FontStyle::Regular
      )

      # Bold / Regular variant (Electrolize-Regular)
      @texts << GSDL::Text.new(
        font: "CustomFamily",
        font_size: 20,
        text: "CustomFamily - Bold / Regular (Resolves to Electrolize)",
        y: 230,
        x: x,
        origin: origin,
        weight: GSDL::FontWeight::Bold,
        style: GSDL::FontStyle::Regular
      )

      # Normal / Italic variant (PressStart2P)
      @texts << GSDL::Text.new(
        font: "CustomFamily",
        font_size: 20,
        text: "CustomFamily - Normal / Italic (Resolves to PressStart)",
        y: 300,
        x: x,
        origin: origin,
        weight: GSDL::FontWeight::Normal,
        style: GSDL::FontStyle::Italic
      )

      # Dynamic, interactive text entity
      @dynamic_text = GSDL::Text.new(
        font: "CustomFamily",
        font_size: 22,
        text: "This text changes styles dynamically every 1.5 seconds!",
        y: 420,
        x: x,
        origin: origin,
        color: GSDL::Color.new(255, 200, 100)
      )
      @texts << @dynamic_text

      # Helper footer
      @texts << GSDL::Text.new(
        text: "Press ESC to Exit",
        y: 520,
        x: x,
        origin: origin,
        font_size: 14,
        color: GSDL::Color.new(150, 150, 150)
      )
    end

    def update(dt : Float32) : Bool
      return false unless super(dt)

      @timer += dt

      # Toggle dynamic text traits every 1.5 seconds to prove dynamic re-rasterization & re-fetching
      cycle = (@timer / 1.5_f32).to_i % 3
      case cycle
      when 0
        if @dynamic_text.weight != GSDL::FontWeight::Normal || @dynamic_text.style != GSDL::FontStyle::Regular
          @dynamic_text.weight = GSDL::FontWeight::Normal
          @dynamic_text.style = GSDL::FontStyle::Regular
        end
      when 1
        if @dynamic_text.weight != GSDL::FontWeight::Bold || @dynamic_text.style != GSDL::FontStyle::Regular
          @dynamic_text.weight = GSDL::FontWeight::Bold
          @dynamic_text.style = GSDL::FontStyle::Regular
        end
      when 2
        if @dynamic_text.weight != GSDL::FontWeight::Normal || @dynamic_text.style != GSDL::FontStyle::Italic
          @dynamic_text.weight = GSDL::FontWeight::Normal
          @dynamic_text.style = GSDL::FontStyle::Italic
        end
      end

      true
    end

    def draw(draw : GSDL::Draw)
      @texts.each(&.draw(draw))
    end
  end

  Game.new.run
end
