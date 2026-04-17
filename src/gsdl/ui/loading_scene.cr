module GSDL
  class LoadingScene(T) < LoadingSceneBase
    property background_texture : Texture?
    property text_color : Color = ColorScheme.get(:ui_text)
    property progress_bar_color : Color = ColorScheme.get(:success)
    property background_color : Color = ColorScheme.get(:ui_bg)

    @text : Text
    @progress_text : Text
    @progress_bar : ProgressBar
    @next_scene_class : T.class
    @data : SwitchData?

    def next_scene_class : Scene.class
      @next_scene_class
    end

    def initialize(@next_scene_class : T.class, @data : SwitchData? = nil)
      super(:loading)

      @text = Text.new(
        text: "Loading Assets...",
        x: Game.width / 2_f32,
        y: Game.height / 2_f32 - 40,
        origin: {0.5_f32, 0.5_f32},
        color: text_color
      )

      @progress_bar = ProgressBar.new(
        x: Game.width / 2_f32,
        y: Game.height / 2_f32,
        width: 400,
        height: 20,
        origin: {0.5_f32, 0.5_f32},
        foreground_color: progress_bar_color,
        background_color: ColorScheme.get(:alt),
        border_color: ColorScheme.get(:border),
        border_width: 2,
        border_radius: 5
      )

      @progress_text = Text.new(
        text: "0%",
        x: Game.width / 2_f32,
        y: Game.height / 2_f32 + 40,
        origin: {0.5_f32, 0.5_f32},
        color: ColorScheme.get(:highlight)
      )
    end

    def update(dt : Float32)
      loader = Game.loader
      progress = loader.progress

      percentage = progress.percentage
      @progress_bar.value = percentage / 100.0_f32
      @progress_text.text = "#{percentage.to_i}%"

      if loader.complete?
        # Create the new scene
        next_scene = T.new
        # Set the data if provided
        next_scene.switch_data = @data if @data
        # Switch to it
        Game.switch(next_scene)
      end
    end

    def draw(draw : Draw)
      if tex = background_texture
        draw.texture(tex, 0, 0, dest_rect: GSDL::FRect.new(w: Game.width, h: Game.height))
      else
        draw.color = background_color
        draw.clear
      end

      @text.color = text_color
      @text.draw(draw)

      @progress_bar.foreground_color = progress_bar_color
      @progress_bar.draw(draw)

      @progress_text.draw(draw)
    end
  end
end
