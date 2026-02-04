module GameSDL
  class Font
    EmptyString = ""

    def self.default
      # TODO: will have to edit bindings to be able to alter the font size
      #   after initialization, so for now, create a new font per size
      @@font_default ||= SDL::TTF::Font.new(default_file, 28)
    end

    def self.create(size : UInt16)
      SDL::TTF::Font.new(default_file, size)
    end

    def self.default_file
      EmptyString
    end
  end
end
