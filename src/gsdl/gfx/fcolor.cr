module GSDL
  alias FColors = Array(FColor)

  struct FColor
    def self.from_hex(hex : String) : FColor
      Color.from_hex(hex: hex).to_fcolor
    end

    def self.random(a : Num = 1_f32) : FColor
      Color.random(a: a.to_f32).to_fcolor
    end

    def self.random_chunks(size : UInt8 = 8, a : Num = 1_f32) : FColor
      Color.random_chunks(size: size, a: a.to_f32).to_fcolor
    end

    def self.random(seed : Int, a : Num = 1_f32) : FColor
      rng = Random.new(seed)

      FColor.new(
        red: rng.rand(0_f32..1_f32),
        green: rng.rand(0_f32..1_f32),
        blue: rng.rand(0_f32..1_f32),
        a: a.to_f32
      )
    end

    @internal : SDL3::FColor

    def r : Float32
      @internal.r
    end

    def r=(value : Float32)
      @internal.r = value
    end

    def g : Float32
      @internal.g
    end

    def g=(value : Float32)
      @internal.g = value
    end

    def b : Float32
      @internal.b
    end

    def b=(value : Float32)
      @internal.b = value
    end

    def a : Float32
      @internal.a
    end

    def a=(value : Float32)
      @internal.a = value
    end

    def to_hex(with_alpha = false) : String
      to_color.to_hex(with_alpha)
    end

    def to_u32 : UInt32
      to_color.to_u32
    end

    macro alias_property(new_name, old_name)
      def {{new_name.id}}; {{old_name.id}}; end
      def {{new_name.id}}=(value); self.{{old_name.id}} = value; end
    end

    alias_property red, r
    alias_property green, g
    alias_property blue, b
    alias_property alpha, a

    def initialize(fcolor : SDL3::FColor)
      @internal = fcolor
    end

    def initialize(r : Num = 0_f32, g : Num = 0_f32, b : Num = 0_f32, a : Num = 1_f32)
      @internal = SDL3::FColor.new(r: r.to_f32, g: g.to_f32, b: b.to_f32, a: a.to_f32)
    end

    def initialize(*, red : Num)
      @internal = SDL3::FColor.new(r: red.to_f32)
    end

    def initialize(*, green : Num)
      @internal = SDL3::FColor.new(g: green.to_f32)
    end

    def initialize(*, blue : Num)
      @internal = SDL3::FColor.new(b: blue.to_f32)
    end

    def initialize(*, red : Num, a : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, a: a.to_f32)
    end

    def initialize(*, green : Num, a : Num)
      @internal = SDL3::FColor.new(g: green.to_f32, a: a.to_f32)
    end

    def initialize(*, blue : Num, a : Num)
      @internal = SDL3::FColor.new(b: blue.to_f32, a: a.to_f32)
    end

    def initialize(*, red : Num, green : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, g: green.to_f32)
    end

    def initialize(*, red : Num, blue : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, b: blue.to_f32)
    end

    def initialize(*, green : Num, blue : Num)
      @internal = SDL3::FColor.new(g: green.to_f32, b: blue.to_f32)
    end

    def initialize(*, red : Num, green : Num, a : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, g: green.to_f32, a: a.to_f32)
    end

    def initialize(*, red : Num, blue : Num, a : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, b: blue.to_f32, a: a.to_f32)
    end

    def initialize(*, green : Num, blue : Num, a : Num)
      @internal = SDL3::FColor.new(g: green.to_f32, b: blue.to_f32, a: a.to_f32)
    end

    def initialize(*, red : Num, green : Num, blue : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, g: green.to_f32, b: blue.to_f32)
    end

    def initialize(*, red : Num, green : Num, blue : Num, a : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, g: green.to_f32, b: blue.to_f32, a: a.to_f32)
    end

    def to_color
      Color.new(@internal.to_color)
    end

    # Returns the wrapped `SDL3::FColor`
    def to_sdl
      @internal
    end

    def lerp(other : self, t : Float32) : self
      self.class.new(
        r: MathUtils.lerp(r, other.r, t),
        g: MathUtils.lerp(g, other.g, t),
        b: MathUtils.lerp(b, other.b, t),
        a: MathUtils.lerp(a, other.a, t)
      )
    end

    # Returns a new color that is a linear interpolation between this color and another.
    def mix(other : self, t : Float32 = 0.5_f32) : self
      lerp(other, t)
    end

    # Multiplies each component of this color by the corresponding component of another color.
    def multiply(other : self) : self
      self.class.new(
        r: r * other.r,
        g: g * other.g,
        b: b * other.b,
        a: a * other.a
      )
    end

    # Alias for `multiply`.
    def merge(other : self) : self
      multiply(other)
    end

    # Multiplies each component of this color by another color.
    def *(other : self) : self
      multiply(other)
    end

    # Multiplies each component of this color by a scalar value.
    def *(scalar : Float) : self
      self.class.new(
        r: r * scalar.to_f32,
        g: g * scalar.to_f32,
        b: b * scalar.to_f32,
        a: a * scalar.to_f32
      )
    end

    # Adds the components of another color to this one.
    def add(other : self) : self
      self.class.new(
        r: r + other.r,
        g: g + other.g,
        b: b + other.b,
        a: a + other.a
      )
    end

    # Adds the components of another color to this one.
    def +(other : self) : self
      add(other)
    end

    # Subtracts the components of another color from this one.
    def subtract(other : self) : self
      self.class.new(
        r: r - other.r,
        g: g - other.g,
        b: b - other.b,
        a: a - other.a
      )
    end

    # Subtracts the components of another color from this one.
    def -(other : self) : self
      subtract(other)
    end

    macro mirror_colors_to_fcolor
      struct FColor
        {% for name in Color.constants %}
          # Check if the constant is actually a Color to avoid mirroring
          # internal metadata or version numbers
          {% if Color.constant(name).is_a?(Color) %}
            {{name.id}} = Color::{{name.id}}.to_fcolor
          {% end %}
        {% end %}
      end
    end

    mirror_colors_to_fcolor
  end
end
