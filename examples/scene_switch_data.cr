require "../src/game_sdl"

module SceneDataEx
  class Game < GSDL::Game
    def initialize
      super(title: "Scene Switch Data Example", width: 800, height: 600)
    end

    def init
      GSDL::Events.esc_exits = false
      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = MenuScene.new
    end

    def check_scenes
      case current_scene = scene
      when MenuScene
        if current_scene.start_game?
          data = GSDL::SwitchData{:from => :menu, :player_pos => 100}
          switch(MainScene.new, data)
        elsif current_scene.exit?
          @exit = true
        end
      when MainScene
        if current_scene.back_to_menu?
          data = GSDL::SwitchData{:from => :main, :status => :completed}
          switch(MenuScene.new, data)
        end
      end
    end
  end

  class MenuScene < GSDL::Scene
    getter? start_game = false
    @text : GSDL::Text
    @info : GSDL::Text?

    def initialize
      super(:menu)
      @text = GSDL::Text.new(
        text: "MENU

Press SPACE to Start",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White,
        align: GSDL::Font::Align::Center
      )
    end

    def init
      if data = switch_data
        @info = GSDL::Text.new(
          text: "Returned from: #{data[:from]}\nStatus: #{data[:status]}",
          x: GSDL::Game.width / 2_f32,
          y: GSDL::Game.height - 50,
          origin: {0.5_f32, 1.0_f32},
          color: GSDL::Color::Gray
        )
      end
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        @start_game = true
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        @exit = true
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
      @info.try &.draw(draw)
    end
  end

  class MainScene < GSDL::Scene
    getter? back_to_menu = false
    @text : GSDL::Text
    @info : GSDL::Text?

    def initialize
      super(:main)
      @text = GSDL::Text.new(
        text: "MAIN SCENE

Press ESC to go back",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Lime,
        align: GSDL::Font::Align::Center
      )
    end

    def init
      if data = switch_data
        @info = GSDL::Text.new(
          text: "Came from: #{data[:from]}\nPlayer Pos: #{data[:player_pos]}",
          x: GSDL::Game.width / 2_f32,
          y: 50,
          origin: {0.5_f32, 0.0_f32},
          color: GSDL::Color::Yellow
        )
      end
    end

    def update(dt : Float32)
      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        @back_to_menu = true
      end
    end

    def draw(draw : GSDL::Draw)
      @text.draw(draw)
      @info.try &.draw(draw)
    end
  end

  Game.new.run
end
