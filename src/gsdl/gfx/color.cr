module GSDL
  alias Colors = Array(Color)

  def self.color(r : Int = 0, g : Int = 0, b : Int = 0, a : Int = 255) : Color
    Color.new(r: r, g: g, b: b, a: a)
  end

  def self.gray(v : Int, a : Int = 255) : Color
    Color.gray(v: v, a: a)
  end

  def self.grey(v : Int, a : Int = 255) : Color
    gray(v: v, a: a)
  end

  struct Color
    def self.from_hex(hex : String) : Color
      Color.new(SDL3::Color.from_hex(hex: hex))
    end

    def self.parse(value : String | Color) : Color
      return value if value.is_a?(Color)

      if value.starts_with?("#")
        return from_hex(value)
      elsif value.starts_with?("rgba(")
        return from_rgba(value)
      elsif value.starts_with?("rgb(")
        return from_rgb(value)
      end

      from_name(value)
    end

    def self.from_rgb(rgb_string : String) : Color
      # rgb(r, g, b)
      parts = rgb_string.gsub("rgb(", "").gsub(")", "").split(',').map(&.strip.to_i)
      Color.new(r: parts[0], g: parts[1], b: parts[2])
    rescue
      White
    end

    def self.from_rgba(rgba_string : String) : Color
      # rgba(r, g, b, a)
      parts = rgba_string.gsub("rgba(", "").gsub(")", "").split(',').map(&.strip.to_i)
      Color.new(r: parts[0], g: parts[1], b: parts[2], a: parts[3])
    rescue
      White
    end

    def self.random(a : UInt8 = 255_u8) : Color
      Color.new(SDL3::Color.random(a: a))
    end

    def self.random_chunks(size : UInt8 = 8_u8, a : UInt8 = 255_u8) : Color
      Color.new(SDL3::Color.random_chunks(size: size, a: a))
    end

    def self.random(seed : Int, a : Int = 255_u8) : Color
      rng = Random.new(seed)

      Color.new(
        red: rng.next_u8,
        green: rng.next_u8,
        blue: rng.next_u8,
        alpha: a.to_u8
      )
    end

    def self.gray(v : Int, a : Int = 255) : Color
      Color.new(r: v, g: v, b: v, a: a)
    end

    def self.grey(v : Int, a : Int = 255) : Color
      gray(v: v, a: a)
    end

    macro generate_from_name
      def self.from_name(name : String) : Color
        case name.downcase
        {% for const in @type.constants %}
        when {{const.stringify.downcase}} then {{const}}
        {% end %}
        else White
        end
      end
    end

    @internal : SDL3::Color

    def r : UInt8
      @internal.r
    end

    def r=(value : UInt8)
      @internal.r = value
    end

    def g : UInt8
      @internal.g
    end

    def g=(value : UInt8)
      @internal.g = value
    end

    def b : UInt8
      @internal.b
    end

    def b=(value : UInt8)
      @internal.b = value
    end

    def a : UInt8
      @internal.a
    end

    def a=(value : UInt8)
      @internal.a = value
    end

    def to_hex(with_alpha = false) : String
      @internal.to_hex(with_alpha)
    end

    def to_u32 : UInt32
      @internal.to_u32
    end

    macro alias_property(new_name, old_name)
      def {{new_name.id}}; {{old_name.id}}; end
      def {{new_name.id}}=(value); self.{{old_name.id}} = value; end
    end

    alias_property red, r
    alias_property green, g
    alias_property blue, b
    alias_property alpha, a

    def initialize(color : SDL3::Color)
      @internal = color
    end

    def initialize(r : Int = 0, g : Int = 0, b : Int = 0, a : Int = 255)
      @internal = SDL3::Color.new(r: r.to_u8, g: g.to_u8, b: b.to_u8, a: a.to_u8)
    end

    def initialize(*, red : Int)
      @internal = SDL3::Color.new(r: red.to_u8)
    end

    def initialize(*, green : Int)
      @internal = SDL3::Color.new(g: green.to_u8)
    end

    def initialize(*, blue : Int)
      @internal = SDL3::Color.new(b: blue.to_u8)
    end

    def initialize(*, red : Int, alpha : Int)
      @internal = SDL3::Color.new(r: red.to_u8, a: alpha.to_u8)
    end

    def initialize(*, green : Int, alpha : Int)
      @internal = SDL3::Color.new(g: green.to_u8, a: alpha.to_u8)
    end

    def initialize(*, blue : Int, alpha : Int)
      @internal = SDL3::Color.new(b: blue.to_u8, a: alpha.to_u8)
    end

    def initialize(*, red : Int, green : Int)
      @internal = SDL3::Color.new(r: red.to_u8, g: green.to_u8)
    end

    def initialize(*, red : Int, blue : Int)
      @internal = SDL3::Color.new(r: red.to_u8, b: blue.to_u8)
    end

    def initialize(*, green : Int, blue : Int)
      @internal = SDL3::Color.new(g: green.to_u8, b: blue.to_u8)
    end

    def initialize(*, red : Int, green : Int, alpha : Int)
      @internal = SDL3::Color.new(r: red.to_u8, g: green.to_u8, a: alpha.to_u8)
    end

    def initialize(*, red : Int, blue : Int, alpha : Int)
      @internal = SDL3::Color.new(r: red.to_u8, b: blue.to_u8, a: alpha.to_u8)
    end

    def initialize(*, green : Int, blue : Int, alpha : Int)
      @internal = SDL3::Color.new(g: green.to_u8, b: blue.to_u8, a: alpha.to_u8)
    end

    def initialize(*, red : Int, green : Int, blue : Int)
      @internal = SDL3::Color.new(r: red.to_u8, g: green.to_u8, b: blue.to_u8)
    end

    def initialize(*, red : Int, green : Int, blue : Int, alpha : Int)
      @internal = SDL3::Color.new(r: red.to_u8, g: green.to_u8, b: blue.to_u8, a: alpha.to_u8)
    end

    def to_fcolor
      FColor.new(@internal.to_fcolor)
    end

    def opaque?
      a == 255
    end

    def white?
      r == 255 && g == 255 && b == 255
    end

    # Returns the wrapped `SDL3::Color`
    def to_sdl
      @internal
    end

    def lerp(other : Color, t : Float32) : Color
      Color.new(
        r: MathUtils.lerp(r.to_f32, other.r.to_f32, t).clamp(0.0_f32, 255.0_f32).to_u8,
        g: MathUtils.lerp(g.to_f32, other.g.to_f32, t).clamp(0.0_f32, 255.0_f32).to_u8,
        b: MathUtils.lerp(b.to_f32, other.b.to_f32, t).clamp(0.0_f32, 255.0_f32).to_u8,
        a: MathUtils.lerp(a.to_f32, other.a.to_f32, t).clamp(0.0_f32, 255.0_f32).to_u8
      )
    end

    # Colors
    Transparent = GSDL.gray(0, 0)

    Black = GSDL.gray(0)
    White = GSDL.gray(255)

    # Grays
    Gray       = GSDL.gray(128)
    Grey       = Gray
    LightGray  = GSDL.gray(224)
    LightGrey  = LightGray
    DarkGray   = GSDL.gray(160)
    DarkGrey   = DarkGray
    DimGray    = GSDL.gray(96)
    DimGrey    = DimGray
    DarkerGray = GSDL.gray(64)
    DarkerGrey = DarkerGray
    Silver     = GSDL.gray(192)
    Snow       = GSDL.color(r: 255, g: 250, b: 250)
    WhiteSmoke = GSDL.color(r: 245, g: 245, b: 245)
    GunSmoke   = GSDL.color(r: 122, g: 124, b: 118)
    Ivory      = GSDL.color(r: 255, g: 255, b: 240)

    # Reds
    Red       = GSDL.color(r: 255)
    DarkRed   = GSDL.color(r: 160)
    Maroon    = GSDL.color(r: 128)
    FireBrick = GSDL.color(r: 178, g: 34, b: 34)
    Crimson   = GSDL.color(r: 220, g: 20, b: 60)
    Tomato    = GSDL.color(r: 255, g: 99, b: 71)
    Salmon    = GSDL.color(r: 250, g: 128, b: 114)

    # Oranges
    Orange     = GSDL.color(r: 255, g: 160)
    OrangeRed  = GSDL.color(r: 255, g: 64)
    DarkOrange = GSDL.color(r: 255, g: 128)
    Coral      = GSDL.color(r: 255, g: 127, b: 80)

    # Yellows
    Yellow      = GSDL.color(r: 255, g: 255)
    Gold        = GSDL.color(r: 255, g: 215)
    GoldenRod   = GSDL.color(r: 218, g: 165, b: 32)
    Khaki       = GSDL.color(r: 240, g: 230, b: 140)
    DarkKhaki   = GSDL.color(r: 189, g: 183, b: 107)
    YellowGreen = GSDL.color(r: 154, g: 205, b: 50)
    Olive       = GSDL.color(r: 128, g: 128)

    # Greens
    Green       = GSDL.color(g: 128)
    Lime        = GSDL.color(g: 255)
    LimeGreen   = GSDL.color(r: 50, g: 205, b: 50)
    DarkGreen   = GSDL.color(g: 100)
    ForestGreen = GSDL.color(r: 34, g: 139, b: 34)
    SpringGreen = GSDL.color(g: 255, b: 127)
    SeaGreen    = GSDL.color(r: 46, g: 139, b: 87)
    GreenYellow = GSDL.color(r: 173, g: 255, b: 47)

    # Blues
    Blue          = GSDL.color(b: 255)
    LightBlue     = GSDL.color(r: 173, g: 216, b: 230)
    DarkBlue      = GSDL.color(b: 139)
    Navy          = GSDL.color(b: 128)
    RoyalBlue     = GSDL.color(r: 65, g: 105, b: 225)
    Cyan          = GSDL.color(b: 255, g: 255)
    Aqua          = Cyan
    DarkCyan      = GSDL.color(g: 139, b: 139)
    Teal          = GSDL.color(g: 128, b: 128)
    Turquoise     = GSDL.color(r: 64, g: 224, b: 208)
    DarkTurquoise = GSDL.color(g: 206, b: 209)

    # Purples
    Purple      = GSDL.color(r: 128, b: 128)
    Magenta     = GSDL.color(r: 255, b: 255)
    Fuschia     = Magenta
    DarkMagenta = GSDL.color(r: 139, b: 139)
    Indigo      = GSDL.color(r: 75, b: 130)
    Violet      = GSDL.color(r: 238, g: 130, b: 238)
    DarkViolet  = GSDL.color(r: 138, g: 43, b: 226)
    Lavender    = GSDL.color(r: 230, g: 230, b: 250)
    DeepPink    = GSDL.color(r: 255, g: 20, b: 147)
    HotPink     = GSDL.color(r: 255, g: 105, b: 180)
    Pink        = GSDL.color(r: 255, g: 192, b: 203)

    # Browns
    Brown       = GSDL.color(r: 165, g: 42, b: 42)
    SaddleBrown = GSDL.color(r: 139, g: 69, b: 19)
    DarkEbony   = GSDL.color(r: 55, g: 49, b: 43)
    Sienna      = GSDL.color(r: 160, g: 82, b: 45)
    Chocolate   = GSDL.color(r: 210, g: 105, b: 30)
    Peru        = GSDL.color(r: 205, g: 133, b: 63)
    SandyWood   = GSDL.color(r: 244, g: 164, b: 96)
    Tan         = GSDL.color(r: 210, g: 180, b: 140)
    Moccasin    = GSDL.color(r: 255, g: 228, b: 181)

    generate_from_name
  end
end
