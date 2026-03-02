require "../src/game_sdl"

module GameEx
  WIDTH  = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "Area Action Example", width: WIDTH, height: HEIGHT)
    end

    def init
      GSDL::Events.esc_exits = true

      GSDL::TextureManager.load("player", "gfx/top_down_player.png")
      GSDL::TextureManager.load("npc", "gfx/skeleton.png")

      GSDL::Input.set(:action) { GSDL::Keys.just_pressed?([GSDL::Keys::Space, GSDL::Keys::Return]) }

      @scene_manager = SceneManager.new
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class Player < GSDL::Sprite
    property move_speed : Float32 = 200_f32
    @dir_text : GSDL::Text?

    def initialize(x : GSDL::Num, y : GSDL::Num)
      super("player", x, y, origin: {0.5_f32, 0.5_f32}, source_rect: GSDL::FRect.new(x: 0, y: 0, w: 24, h: 40))
    end

    def update(dt : Float32)
      super

      dx = 0_f32
      dy = 0_f32

      up = GSDL::Keys.pressed?([GSDL::Keys::Up, GSDL::Keys::W])
      down = GSDL::Keys.pressed?([GSDL::Keys::Down, GSDL::Keys::S])
      left = GSDL::Keys.pressed?([GSDL::Keys::Left, GSDL::Keys::A])
      right = GSDL::Keys.pressed?([GSDL::Keys::Right, GSDL::Keys::D])

      dy -= 1 if up
      dy += 1 if down
      dx -= 1 if left
      dx += 1 if right

      if dx != 0 || dy != 0
        mag = Math.sqrt(dx * dx + dy * dy)
        @x += (dx / mag) * move_speed * dt
        @y += (dy / mag) * move_speed * dt

        # Update direction
        if up && right
          self.direction = GSDL::Direction::UpRight
        elsif up && left
          self.direction = GSDL::Direction::UpLeft
        elsif down && right
          self.direction = GSDL::Direction::DownRight
        elsif down && left
          self.direction = GSDL::Direction::DownLeft
        elsif up
          self.direction = GSDL::Direction::Up
        elsif down
          self.direction = GSDL::Direction::Down
        elsif left
          self.direction = GSDL::Direction::Left
        elsif right
          self.direction = GSDL::Direction::Right
        end
      end
    end

    def draw(draw : GSDL::Draw)
      super
      draw_direction(draw)
    end

    def draw_direction(draw : GSDL::Draw)
      font = GSDL::Font.default.copy
      font.size = 8

      text = @dir_text ||= GSDL::Text.new(
        font: font,
        text: "dir: #{direction}",
        origin: {0.5_f32, 1.0_f32},
        color: GSDL::Color::White,
        z_index: 1000
      )
      text.text = "dir: #{direction}"
      text.x = x
      text.y = y - draw_height / 2 - 4
      text.draw(draw)
    end

    # Custom area bounding box that acts as an "interaction reach"
    def area_bounding_box : GSDL::FRect
      # Make area bigger than sprite to simulate reach
      GSDL::FRect.new(
        x: -32,
        y: -32,
        w: draw_width + 64,
        h: draw_height + 64
      )
    end
  end

  class NPC < GSDL::Sprite
    @dir_text : GSDL::Text?

    def initialize(x : GSDL::Num, y : GSDL::Num)
      super("npc", x, y, origin: {0.5_f32, 0.5_f32}, source_rect: GSDL::FRect.new(x: 0, y: 0, w: 32, h: 64))
      @tint = GSDL::Color::White
    end

    def update(dt : Float32)
      super
    end

    def draw(draw : GSDL::Draw)
      super
      draw_direction(draw)
    end

    def draw_direction(draw : GSDL::Draw)
      font = GSDL::Font.default.copy
      font.size = 8

      text = @dir_text ||= GSDL::Text.new(
        font: font,
        text: "dir: #{direction}",
        origin: {0.5_f32, 1.0_f32},
        color: GSDL::Color::White,
        z_index: 1000
      )
      text.text = "dir: #{direction}"
      text.x = x
      text.y = y - draw_height / 2 - 4
      text.draw(draw)
    end
  end

  class SceneManager < GSDL::SceneManager
    def initialize
      super
      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    @player : Player
    @npcs : Array(NPC)

    def initialize
      super(:start)
      @player = Player.new(400, 300)
      @npcs = [
        NPC.new(250, 300),
        NPC.new(550, 300),
        NPC.new(400, 150),
        NPC.new(400, 450)
      ]
    end

    def update(dt : Float32)
      @player.update(dt)

      # Reset colors
      @npcs.each { |npc| npc.tint = GSDL::Color::White }

      # Highlight NPC if player is facing them, in area, and press action
      @player.on_area_trigger(@npcs.map(&.as(GSDL::Area)), :action) do |area|
        npc = area.as(NPC)
        npc.tint = GSDL::Color::Green
        puts "Triggered action on NPC at #{npc.x}, #{npc.y}!"
      end

      # Also just show red if facing and in area without action (hover state)
      @player.on_area_trigger(@npcs.map(&.as(GSDL::Area))) do |area|
        npc = area.as(NPC)
        # only tint if we didn't just turn it green
        npc.tint = GSDL::Color::Red if npc.tint == GSDL::Color::White
      end

    end

    def draw(draw : GSDL::Draw)
      @npcs.each(&.draw(draw))
      @player.draw(draw)

      # draw interaction areas for debugging
      draw.rect_outline(@player.area_box, GSDL::Color::Blue)
      @npcs.each do |npc|
        draw.rect_outline(npc.area_box, GSDL::Color::Yellow)
      end
    end
  end

  Game.new.run
end
