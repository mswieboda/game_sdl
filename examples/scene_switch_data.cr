require "../src/game_sdl"

module SceneDataEx
  class Game < GSDL::Game
    def initialize
      super(title: "Scene Switch Data Example")
    end

    def init
      GSDL::Events.esc_exits = false
      GSDL::Game.push(MenuScene.new)
    end

    def check_scenes
      s = scene
      if s.name == :menu && s.as(MenuScene).start_game?
        data = {:from => :menu, :player_pos => "100,200"} of Symbol => GSDL::SwitchDataValue
        switch(MainScene.new, data)
      elsif s.name == :main && s.as(MainScene).back_to_menu?
        data = {:from => :main, :status => :completed} of Symbol => GSDL::SwitchDataValue
        switch(MenuScene.new, data)
      end
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class MenuScene < GSDL::Scene
    getter? start_game = false
    @text : GSDL::Text
    @info : GSDL::Text?

    def initialize
      super(:menu)
      @text = GSDL::Text.new(
        text: "MENU\n\nPress SPACE to Start",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::White,
        align: GSDL::Font::Align::Center
      )
    end

    def init
      GSDL::Input.set(:start_game) { GSDL::Keys.just_pressed?(GSDL::Keys::Space) }

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
      if GSDL::Input.action?(:start_game)
        @start_game = true
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        GSDL::Game.quit!
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
        text: "MAIN SCENE\n\nPress ESC to go back",
        x: GSDL::Game.width / 2_f32,
        y: GSDL::Game.height / 2_f32,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL::Color::Lime,
        align: GSDL::Font::Align::Center
      )
    end

    def init
      GSDL::Input.set(:back_to_menu) { GSDL::Keys.just_pressed?(GSDL::Keys::Escape) }

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
      if GSDL::Input.action?(:back_to_menu)
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
