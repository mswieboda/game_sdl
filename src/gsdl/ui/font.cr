module GSDL
  class Font
    EmptyString = ""

    def self.default
      # TODO: will have to edit bindings to be able to alter the font size
      #   after initialization, so for now, create a new font per size
      @@font_default ||= SDL3::TTF::Font.open(default_file, 28.0_f32)
    end

    def self.create(size : UInt16)
      SDL3::TTF::Font.open(default_file, size.to_f32)
    end

    def self.default_file
      EmptyString
    end
  end
end
