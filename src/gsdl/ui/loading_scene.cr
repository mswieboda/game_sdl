module GSDL
  class LoadingScene(T) < Scene
    @text : Text
    @progress_text : Text
    @next_scene_class : T.class

    def initialize(@next_scene_class : T.class)
      super(:loading)
      @text = Text.new(
        text: "Loading Assets...",
        x: Game.width / 2_f32,
        y: Game.height / 2_f32 - 20,
        origin: {0.5_f32, 0.5_f32},
        color: Color::White
      )
      @progress_text = Text.new(
        text: "0%",
        x: Game.width / 2_f32,
        y: Game.height / 2_f32 + 20,
        origin: {0.5_f32, 0.5_f32},
        color: Color::Cyan
      )
    end

    def update(dt : Float32)
      loader = Game.instance.loader
      progress = loader.progress
      
      @progress_text.text = "#{progress.percentage.to_i}%"
      
      if loader.complete?
        Game.instance.scene_manager.switch(T.new)
      end
    end

    def draw(draw : Draw)
      @text.draw(draw)
      @progress_text.draw(draw)
    end
  end
end
