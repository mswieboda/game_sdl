require "../src/game_sdl"

module TileMapStress
  WIDTH = 800
  HEIGHT = 600
  TILE_SIZE = 32

  class Game < GSDL::Game
    def initialize
      super(title: "TileMap Stress Test", width: WIDTH, height: HEIGHT)
        end

    def init
      GSDL::Events.esc_exits = true

      # Map camera movement actions
      GSDL::Input.set(:camera_up) { GSDL::Keys.pressed?(GSDL::Keys::W) || GSDL::Keys.pressed?(GSDL::Keys::Up) }
      GSDL::Input.set(:camera_down) { GSDL::Keys.pressed?(GSDL::Keys::S) || GSDL::Keys.pressed?(GSDL::Keys::Down) }
      GSDL::Input.set(:camera_left) { GSDL::Keys.pressed?(GSDL::Keys::A) || GSDL::Keys.pressed?(GSDL::Keys::Left) }
      GSDL::Input.set(:camera_right) { GSDL::Keys.pressed?(GSDL::Keys::D) || GSDL::Keys.pressed?(GSDL::Keys::Right) }
      GSDL::Game.push(StartScene.new)
        end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end

    def load_textures
      [{"tiles", "gfx/tiles.png"}]
    end
  end

  class StartScene < GSDL::Scene
    @tile_map : GSDL::TileMap

    def initialize
      super(:start)

      texture = GSDL::TextureManager.get("tiles")
      tileset = GSDL::Tileset.new(texture, TILE_SIZE, TILE_SIZE, first_gid: 1)

      @tile_map = GSDL::TileMap.new(TILE_SIZE, TILE_SIZE)
      @tile_map.add_tileset("tiles", tileset)

      puts "Generating 500x500 map..."
      # Create a 500x500 map (enough to slow down without freezing)
      map_data = Array.new(500) do |y|
        Array.new(500) do |x|
          (x % 10) + 1 # just some random tiles
        end
      end
      puts "Map generated."

      @tile_map.load_map_data(map_data)
      camera.type = GSDL::Camera::Type::Manual
      camera.speed = 1000.0_f32
    end

    def update(dt : Float32)
      camera.update(dt)

      # Test update culling
      @tile_map.update(dt)

      # Toggle culling state on key press
      if GSDL::Keys.just_pressed?(GSDL::Keys::C)
        GSDL::Game.draw_instance.culling_enabled = !GSDL::Game.draw_instance.culling_enabled
      end
    end

    def draw(draw : GSDL::Draw)
      @tile_map.draw(draw)

      # debug info
      culling_active = draw.culling_enabled
      status_text = culling_active ? "ENABLED" : "DISABLED"
      color = culling_active ? GSDL::Color::Lime : GSDL::Color::Red

      text = GSDL::Text.new(
        text: "Culling: #{status_text} (PRESS 'C' TO TOGGLE)\nCamera: #{camera.x.to_i}, #{camera.y.to_i}\nMap Size: 500x500",
        x: 10,
        y: 10,
        color: color
      )
      text.z_index = 100
      text.draw(draw)
    end
  end

  Game.new.run
end