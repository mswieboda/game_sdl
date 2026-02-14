module GSDL
  alias Color = SDL3::Color

  def self.color(r : UInt8 = 0, g : UInt8 = 0, b : UInt8 = 0, a : UInt8 = 255) : Color
    Color.new(r: r, g: g, b: b, a: a)
  end

  def self.color_all(value : UInt8, a : UInt8 = 255) : Color
    color(r: value, g: value, b: value, a: a)
  end

  module Colors
    def self.from_hex(hex : String)
      code = hex.lchop('#').lchop("0x")
      alpha = code[6..7].empty? ? "ff" : code[6..7]

      Color.new(
        r: code[0..1].to_u8(base: 16),
        g: code[2..3].to_u8(base: 16),
        b: code[4..5].to_u8(base: 16),
        a: alpha.to_u8(base: 16)
      )
    end

    def self.random(a : UInt8 = 255)
      Color.new(
        r: rand(256),
        g: rand(256),
        b: rand(256),
        a: a
      )
    end

    def self.random_chunks(size : UInt8 = 8, a : UInt8 = 255)
      rand_max = (256 // size) + 1

      Color.new(
        r: rand(rand_max) * size,
        g: rand(rand_max) * size,
        b: rand(rand_max) * size,
        a: a
      )
    end

    def self.to_u32(color : Color)
      (color.r.to_u32 << 24) | (color.g.to_u32 << 16) | (color.b.to_u32 << 8) | color.a.to_u32
    end

    def self.to_hex(color : Color, with_alpha = false)
      hex = "#"
      hex += color.r.to_s(base: 16, upcase: true)
      hex += color.g.to_s(base: 16, upcase: true)
      hex += color.b.to_s(base: 16, upcase: true)
      hex += color.a.to_s(base: 16, upcase: true) if with_alpha
    end

    # TODO: methods like:
    # - darken
    # - lighten
    # - setting with percentages
    # - lerping to another color
    # - more research color math techniques/options online

    Transparent = GSDL.color_all(0, 0)

    Black = GSDL.color_all(0)
    White = GSDL.color_all(255)

    # Grays
    Gray       = GSDL.color_all(128)
    Grey       = Gray
    LightGray  = GSDL.color_all(224)
    LightGrey  = LightGray
    DarkGray   = GSDL.color_all(160)
    DarkGrey   = DarkGray
    DimGray    = GSDL.color_all(96)
    DimGrey    = DimGray
    DarkerGray = GSDL.color_all(64)
    DarkerGrey = DarkerGray
    Silver     = GSDL.color_all(192)
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

    # Palettes
    Palette = Array(Color)

    module Palettes
      Primary = [Red, Blue, Yellow]
      RYB = Primary
      PrimaryRYB = Primary
      RGB = [Red, Green, Blue]
      PrimaryRGB = RGB

      Secondary = [Orange, Green, Purple]
      SecondaryRYB = Secondary
      SecondaryRGB = [Cyan, Magenta, Yellow]

      Rainbow = [Red, Orange, Yellow, Green, Blue, Indigo, Violet]
    end
  end
end
