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
    end
  end
end
