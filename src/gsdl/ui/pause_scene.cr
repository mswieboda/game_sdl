module GSDL
  class PauseScene < Scene
    @menu : Menu
    @title : Text
    @background : Box

    def initialize
      super(:pause)
      @z_index = 1000

      @title = Text.new(
        text: "PAUSED",
        x: Game.width / 2_f32,
        y: Game.height / 2_f32 - 100,
        origin: {0.5_f32, 0.5_f32},
        color: Color::White,
        scale: {2_f32, 2_f32},
        z_index: @z_index
      )

      items = [
        {:resume, "Resume"},
        {:exit, "Exit"}
      ]

      @menu = Menu.new(
        is_selected: ->(x : Num, y : Num, w : Num, h : Num) {
          Keys.just_pressed?([Keys::Space, Keys::Return]) ||
            Mouse.clicked_in?(x, y, w, h)
        },
        is_next: -> { Keys.just_pressed?([Keys::S, Keys::Down]) },
        is_previous: -> { Keys.just_pressed?([Keys::W, Keys::Up]) },
        items: items,
        x: Game.width // 2,
        y: Game.height // 2,
        origin: {0.5_f32, 0.5_f32},
        on_select: ->(id : Symbol) {
          if id == :resume
            Game.paused = false
          elsif id == :exit
            Game.quit!
          end
          nil
        },
        mouse_hover: true,
        background_box: Box.new(color: Color.new(0, 0, 0, 150), border_radius: 16),
        padding: 20,
        separation: 10,
        z_index: @z_index
      )

      @background = Box.new(
        x: 0,
        y: 0,
        width: Game.width,
        height: Game.height,
        color: Color.new(0, 0, 0, 100),
        z_index: @z_index - 1
      )
    end

    def update(dt : Float32)
      @menu.update(dt)

      if Keys.just_pressed?([Keys::Escape])
        Game.paused = false
        return
      end
    end

    def draw(draw : Draw)
      @background.draw(draw)
      @title.draw(draw)
      @menu.draw(draw)
    end
  end
end
