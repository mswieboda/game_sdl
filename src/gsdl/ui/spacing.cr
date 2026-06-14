module GSDL
  module UI
    struct Spacing
      property top : Int32
      property right : Int32
      property bottom : Int32
      property left : Int32

      def initialize(all : Int32 = 0)
        @top = @right = @bottom = @left = all
      end

      def initialize(horizontal : Int32, vertical : Int32)
        @right = @left = horizontal
        @top = @bottom = vertical
      end

      def initialize(@top, @right, @bottom, @left)
      end

      def vertical
        top + bottom
      end

      def horizontal
        left + right
      end

      # Convert a SpacingInput to a Spacing.
      # An Int32 is treated as `all:` (uniform spacing on every side).
      def self.from(value : SpacingInput) : Spacing
        case value
        when Int32 then Spacing.new(all: value)
        else            value
        end
      end
    end

    # Shorthand type accepted anywhere a Spacing is expected.
    # Pass a plain Int32 to mean "all sides equal", or pass a Spacing directly.
    alias SpacingInput = Spacing | Int32
  end
end
