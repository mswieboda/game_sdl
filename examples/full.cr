require "../src/game_sdl"

module GameEx
  class FullGame < GSDL::Game
    def initialize
      super(title: "Full GSDL Example", width: 800, height: 600)
    end

    def init
      # NOTE: setting this to `false` to test transition_out
      GSDL::Events.esc_exits = false
      GSDL::Game.push(StartScene.new)
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_default_font_atlas
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [
        {"ship", "gfx/ship.png"},
        {"coin", "gfx/coin.png"},
        {"tiles", "gfx/tiles.png"},
      ]
    end

    def load_audio
      [{"race_car", "sfx/race_car.wav"}]
    end
  end

  class StartScene < GSDL::Scene
    @text : GSDL::Text
    @ship : GSDL::Sprite
    @coin : GSDL::AnimatedSprite
    @audio : GSDL::Audio
    @box : GSDL::Box
    @shapes : Array(GSDL::Shape)

    def initialize
      # --- Transitions ---
      transition_in = GSDL::FadeTransition.new(
        direction: GSDL::TransitionDirection::In,
        duration: 0.75_f32,
        started: true
      )
      transition_out = GSDL::FadeTransition.new(
        direction: GSDL::TransitionDirection::Out,
        duration: 0.5_f32
      )

      super(:start, transition_in: transition_in, transition_out: transition_out)

      # --- UI / Text ---
      @text = GSDL::Text.new(
        text: "Full Example\nPress SPACE for SFX",
        origin: {0.5_f32, 0.0_f32},
        color: GSDL::Color::White,
        h_align: GSDL::HorizontalAlign::Center
      )
      @text.x = GSDL::Game.width / 2_f32
      @text.y = 50

      # --- Standard Sprite ---
      @ship = GSDL::Sprite.new(
        key: :ship,
        origin: {0.5_f32, 0.5_f32},
        x: 128,
        y: 448,
        source_rect: GSDL::FRect.new(w: 128),
        scale: {1.5_f32, 0.75_f32}
      )

      # --- Animated Sprite ---
      # Assuming coin.png is a strip of frames.
      # Let's guess 16x16 frames for now.
      @coin = GSDL::AnimatedSprite.new(
        key: :coin,
        width: 32, height: 32,
        origin: {0.5_f32, 0.5_f32},
        x: 624,
        y: 320,
        scale: {0.5_f32, 0.5_f32}
      )

      # Setup a simple animation for the coin
      @coin.add("spin", [0, 1, 2, 3, 4, 3, 2, 1], 8, loops: true)
      @coin.play("spin")
      @coin.play("spin")

      # --- Audio ---
      @audio = GSDL::AudioManager.get(:race_car)

      # --- Shape and Shape Transparency ---
      bg = GSDL::Box.new(
        width: 96,
        height: 192,
        x: 96,
        y: 192,
        origin: {0.5_f32, 0.5_f32},
        border_radius: 32,
        color: GSDL.gray(128)
      )
      @box = GSDL::Box.new(
        width: 64,
        height: 128,
        x: 128,
        y: 192,
        origin: {0.5_f32, 0.5_f32},
        color: GSDL.color(g: 255, a: 96),
        z_index: 3
      )
      oval = GSDL::Oval.new(
        x: 256,
        y: 256,
        radius_x: 64,
        radius_y: 32,
        color: GSDL::Color::Cyan,
        origin: {0.5_f32, 0.5_f32}
      )
      @shapes = [bg, @box, oval] of GSDL::Shape

      # --- Shape Tween ---
      @box.tweens.clear
      tween = @box.tween
      tween.add_sequence([
        {
          :duration => 0.8,
          :rotation => 0.0,
          :scale    => {2.0_f32, 2.0_f32},
          :easing   => :ease_in_out,
        },
        {
          :duration => 1.5,
          :rotation => -180.0,
          :scale    => {0.75_f32, 0.75_f32},
        },
        {
          :duration => 0.5,
          :rotation => 270.0,
          :scale    => {1.0_f32, 1.0_f32},
          :easing   => :ease_out,
        },
        {
          :duration => 1.0,
          :rotation => 0.0,
          :scale    => {1_f32, 1_f32},
          :easing   => :ease_out,
        },
      ])
      tween.start(loop: true)

      # --- Tile Map ---
      tile_size = 32
      texture = GSDL::TextureManager.get(:tiles)
      tileset = GSDL::Tileset.new(texture, tile_size, tile_size)

      @tile_map = GSDL::TileMap.new(tile_size, tile_size)
      @tile_map.add_tileset("tiles", tileset)

      # Manually define some map data
      # 0 = empty, other are tiles from tiles.png asset
      map_data = [
        [1, 2, 3, 4, 5, 6, 7, 8, 9],
        [10, 11, 12, 13, 14, 15, 16, 17, 18]
      ]
      @tile_map.load_map_data(map_data)

    end

    def update(dt : Float32)
      # Rotate the ship
      @ship.rotation += 90_f32 * dt

      # Update animations
      @coin.update(dt)

      # Input handling for Sound
      if GSDL::Keys.just_pressed?(GSDL::Keys::Space)
        if @audio.playing?
          @audio.pause
        elsif @audio.paused?
          @audio.resume
        else
          @audio.play
        end
      end

      if @audio.paused?
        # Visual feedback
        @text.color = GSDL::Color::Yellow
      elsif @audio.playing?
        # Visual feedback
        @text.color = GSDL::Color::Lime
        @text.scale = {1.2_f32, 1.2_f32}
      end

      if @audio.finished?
        # Return to normal
        @text.color = GSDL::Color::White
        @text.scale = {1.0_f32, 1.0_f32}
      end

      if GSDL::Keys.just_pressed?(GSDL::Keys::Escape)
        transition_out.start
      end

      @text.update(dt)

      # Update box for tweens
      @box.update(dt)
    end

    def draw_camera_view(draw : GSDL::Draw)
      @tile_map.draw(draw)

      @text.draw(draw)
      @ship.draw(draw)
      @coin.draw(draw)
      @shapes.each(&.draw(draw))
    end
  end

  FullGame.new.run
end
