module GSDL
  alias MostInts = UInt8 | UInt16 | UInt32 | Int8 | Int16 | Int32
  alias Color = SDL3::Color
  alias Colors = Array(Color)

  def self.color(r : Int = 0, g : Int = 0, b : Int = 0, a : Int = 255) : Color
    Color.new(r: r, g: g, b: b, a: a)
  end

  def self.gray(v = 127, a = 255) : Color
    Color.gray(v: v, a: a)
  end

  def self.grey(v = 127, a = 255) : Color
    gray(v: v, a: a)
  end
end

struct LibSDL3::Color
  def self.color(r : Int = 0, g : Int = 0, b : Int = 0, a : Int = 255) : LibSDL3::Color
    LibSDL3::Color.new(r: r, g: g, b: b, a: a)
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

  def self.gray(v = 127, a = 255) : Color
    Color.new(r: v, g: v, b: v, a: a)
  end

  def self.grey(v = 127, a = 255) : Color
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

  def red : UInt8
    @r
  end

  def red=(red : GSDL::MostInts)
    @r = red.to_u8
  end

  def green : UInt8
    @g
  end

  def green=(green : GSDL::MostInts)
    @g = green.to_u8
  end

  def blue : UInt8
    @b
  end

  def blue=(blue : GSDL::MostInts)
    @b = blue.to_u8
  end

  def alpha : UInt8
    @a
  end

  def alpha=(alpha : GSDL::MostInts)
    @a = alpha.to_u8
  end

  def opaque?
    @a == 255
  end

  def white?
    @r == 255 && @g == 255 && @b == 255
  end

  def lerp(other : LibSDL3::Color, t : Float32) : LibSDL3::Color
    LibSDL3::Color.new(
      r: GSDL::MathUtils.lerp(@r.to_f32, other.r.to_f32, t).clamp(0.0_f32, 255.0_f32).to_u8,
      g: GSDL::MathUtils.lerp(@g.to_f32, other.g.to_f32, t).clamp(0.0_f32, 255.0_f32).to_u8,
      b: GSDL::MathUtils.lerp(@b.to_f32, other.b.to_f32, t).clamp(0.0_f32, 255.0_f32).to_u8,
      a: GSDL::MathUtils.lerp(@a.to_f32, other.a.to_f32, t).clamp(0.0_f32, 255.0_f32).to_u8
    )
  end

  # Returns a new color that is a linear interpolation between this color and another.
  def mix(other : LibSDL3::Color, t : Float32 = 0.5_f32) : LibSDL3::Color
    lerp(other, t)
  end

  # Multiplies each component of this color by the corresponding component of another color,
  # normalized to 0-255. This is useful for tinting or combining two colors.
  def multiply(other : LibSDL3::Color) : LibSDL3::Color
    LibSDL3::Color.new(
      r: (@r.to_u32 * other.r.to_u32 / 255).to_u8,
      g: (@g.to_u32 * other.g.to_u32 / 255).to_u8,
      b: (@b.to_u32 * other.b.to_u32 / 255).to_u8,
      a: (@a.to_u32 * other.a.to_u32 / 255).to_u8
    )
  end

  # Alias for `multiply`.
  def merge(other : LibSDL3::Color) : LibSDL3::Color
    multiply(other)
  end

  # Multiplies each component of this color by another color.
  def *(other : LibSDL3::Color) : LibSDL3::Color
    multiply(other)
  end

  # Multiplies each component of this color by a scalar value, clamping the result to 0-255.
  def *(scalar : Float) : LibSDL3::Color
    LibSDL3::Color.new(
      r: (@r.to_f32 * scalar).clamp(0_f32, 255_f32).to_u8,
      g: (@g.to_f32 * scalar).clamp(0_f32, 255_f32).to_u8,
      b: (@b.to_f32 * scalar).clamp(0_f32, 255_f32).to_u8,
      a: (@a.to_f32 * scalar).clamp(0_f32, 255_f32).to_u8
    )
  end

  # Adds the components of another color to this one, clamping the result to 0-255.
  def add(other : LibSDL3::Color) : LibSDL3::Color
    Color.new(
      r: (@r.to_i32 + other.r.to_i32).clamp(0, 255).to_u8,
      g: (@g.to_i32 + other.g.to_i32).clamp(0, 255).to_u8,
      b: (@b.to_i32 + other.b.to_i32).clamp(0, 255).to_u8,
      a: (@a.to_i32 + other.a.to_i32).clamp(0, 255).to_u8
    )
  end

  # Adds the components of another color to this one.
  def +(other : LibSDL3::Color) : LibSDL3::Color
    add(other)
  end

  # Subtracts the components of another color from this one, clamping the result to 0-255.
  def subtract(other : LibSDL3::Color) : LibSDL3::Color
    Color.new(
      r: (r.to_i32 - other.r.to_i32).clamp(0, 255).to_u8,
      g: (g.to_i32 - other.g.to_i32).clamp(0, 255).to_u8,
      b: (b.to_i32 - other.b.to_i32).clamp(0, 255).to_u8,
      a: (a.to_i32 - other.a.to_i32).clamp(0, 255).to_u8
    )
  end

  # Subtracts the components of another color from this one.
  def -(other : LibSDL3::Color) : LibSDL3::Color
    subtract(other)
  end

  def transparent?
    self == Transparent
  end

  def white?
    self == White
  end

  def black?
    self == Black
  end

  # Colors
  Transparent = gray(0, 0)

  Black = gray(0)
  White = gray(255)

  # Grays
  Gray       = gray(128)
  Grey       = Gray
  LightGray  = gray(224)
  LightGrey  = LightGray
  DarkGray   = gray(160)
  DarkGrey   = DarkGray
  DimGray    = gray(96)
  DimGrey    = DimGray
  DarkerGray = gray(64)
  DarkerGrey = DarkerGray
  Silver     = gray(192)
  Snow       = color(r: 255, g: 250, b: 250)
  WhiteSmoke = color(r: 245, g: 245, b: 245)
  GunSmoke   = color(r: 122, g: 124, b: 118)
  Ivory      = color(r: 255, g: 255, b: 240)

  # Reds
  Red       = color(r: 255)
  DarkRed   = color(r: 160)
  Maroon    = color(r: 128)
  FireBrick = color(r: 178, g: 34, b: 34)
  Crimson   = color(r: 220, g: 20, b: 60)
  Tomato    = color(r: 255, g: 99, b: 71)
  Salmon    = color(r: 250, g: 128, b: 114)

  # Oranges
  Orange     = color(r: 255, g: 160)
  OrangeRed  = color(r: 255, g: 64)
  DarkOrange = color(r: 255, g: 128)
  Coral      = color(r: 255, g: 127, b: 80)

  # Yellows
  Yellow      = color(r: 255, g: 255)
  Gold        = color(r: 255, g: 215)
  GoldenRod   = color(r: 218, g: 165, b: 32)
  Khaki       = color(r: 240, g: 230, b: 140)
  DarkKhaki   = color(r: 189, g: 183, b: 107)
  YellowGreen = color(r: 154, g: 205, b: 50)
  Olive       = color(r: 128, g: 128)

  # Greens
  Green       = color(g: 128)
  Lime        = color(g: 255)
  LimeGreen   = color(r: 50, g: 205, b: 50)
  DarkGreen   = color(g: 100)
  ForestGreen = color(r: 34, g: 139, b: 34)
  SpringGreen = color(g: 255, b: 127)
  SeaGreen    = color(r: 46, g: 139, b: 87)
  GreenYellow = color(r: 173, g: 255, b: 47)

  # Blues
  Blue          = color(b: 255)
  LightBlue     = color(r: 173, g: 216, b: 230)
  DarkBlue      = color(b: 139)
  Navy          = color(b: 128)
  RoyalBlue     = color(r: 65, g: 105, b: 225)
  Cyan          = color(b: 255, g: 255)
  Aqua          = Cyan
  DarkCyan      = color(g: 139, b: 139)
  Teal          = color(g: 128, b: 128)
  Turquoise     = color(r: 64, g: 224, b: 208)
  DarkTurquoise = color(g: 206, b: 209)

  # Purples
  Purple      = color(r: 128, b: 128)
  Magenta     = color(r: 255, b: 255)
  Fuschia     = Magenta
  DarkMagenta = color(r: 139, b: 139)
  Indigo      = color(r: 75, b: 130)
  Violet      = color(r: 238, g: 130, b: 238)
  DarkViolet  = color(r: 138, g: 43, b: 226)
  Lavender    = color(r: 230, g: 230, b: 250)
  DeepPink    = color(r: 255, g: 20, b: 147)
  HotPink     = color(r: 255, g: 105, b: 180)
  Pink        = color(r: 255, g: 192, b: 203)

  # Browns
  Brown       = color(r: 165, g: 42, b: 42)
  SaddleBrown = color(r: 139, g: 69, b: 19)
  DarkEbony   = color(r: 55, g: 49, b: 43)
  Sienna      = color(r: 160, g: 82, b: 45)
  Chocolate   = color(r: 210, g: 105, b: 30)
  Peru        = color(r: 205, g: 133, b: 63)
  SandyWood   = color(r: 244, g: 164, b: 96)
  Tan         = color(r: 210, g: 180, b: 140)
  Moccasin    = color(r: 255, g: 228, b: 181)

  generate_from_name
end
