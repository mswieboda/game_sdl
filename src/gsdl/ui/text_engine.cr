module GSDL
  class TextEngine
    alias Type = SDL3::TTF::TextEngine::Type

    def self.create(draw : Draw) : TextEngine
      TextEngine.new(SDL3::TTF::TextEngine.create(draw.to_sdl))
    end

    def self.create_surface_text_engine : TextEngine
      TextEngine.new(SDL3::TTF::TextEngine.create_surface_text_engine)
    end

    @internal : SDL3::TTF::TextEngine

    def destroy : Void
      @internal.destroy
    end

    def type : Type
      @internal.type
    end

    def initialize(engine : SDL3::TTF::TextEngine)
      @internal = engine
    end

    def create_text(font : Font, text : String) : Text
      Text.new(@internal.create_text(font: font.to_sdl, text: text))
    end

    def to_sdl : SDL3::TTF::TextEngine
      @internal
    end
  end
end
