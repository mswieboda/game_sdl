module GSDL
  module Physics
    @@gravity = Point.new(0, 0)

    def self.gravity
      @@gravity
    end

    def self.gravity=(value : Point)
      @@gravity = value
    end

    def self.gravity=(value : Tuple(Num, Num))
      @@gravity = Point.new(value)
    end
  end
end
