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
        alpha: a.to_f32
      )
    end

    @internal : SDL3::FColor

    delegate r, g, b, a, to_color, to_hex, to_u32, to: @internal

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

    def initialize(r : Num = 0_f32, g : Num = 0_f32, b : Num = 0_f32, alpha : Num = 1_f32)
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

    def initialize(*, red : Num, alpha : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, a: alpha.to_f32)
    end

    def initialize(*, green : Num, alpha : Num)
      @internal = SDL3::FColor.new(g: green.to_f32, a: alpha.to_f32)
    end

    def initialize(*, blue : Num, alpha : Num)
      @internal = SDL3::FColor.new(b: blue.to_f32, a: alpha.to_f32)
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

    def initialize(*, red : Num, green : Num, alpha : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, g: green.to_f32, a: alpha.to_f32)
    end

    def initialize(*, red : Num, blue : Num, alpha : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, b: blue.to_f32, a: alpha.to_f32)
    end

    def initialize(*, green : Num, blue : Num, alpha : Num)
      @internal = SDL3::FColor.new(g: green.to_f32, b: blue.to_f32, a: alpha.to_f32)
    end

    def initialize(*, red : Num, green : Num, blue : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, g: green.to_f32, b: blue.to_f32)
    end

    def initialize(*, red : Num, green : Num, blue : Num, alpha : Num)
      @internal = SDL3::FColor.new(r: red.to_f32, g: green.to_f32, b: blue.to_f32, a: alpha.to_f32)
    end

    def to_color
      Color.new(@internal.to_color)
    end

    # Returns the wrapped `SDL3::FColor`
    def to_sdl
      @internal
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
