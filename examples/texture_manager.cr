require "../src/game_sdl" # Assuming game_sdl.cr is the main entry point for GSDL

module GameEx
  WIDTH = 800
  HEIGHT = 600

  class Game < GSDL::Game
    def initialize
      super(title: "GSDL::TemplateManager Ex", width: WIDTH, height: HEIGHT)

      @scene_manager = SceneManager.new
    end

    def load_textures
      # Load the player texture
      # The path is relative to the executable's working directory
      GSDL::TextureManager.load("player", "./assets/gfx/player.png")
    end
  end

  class SceneManager < GSDL::SceneManager
    getter start

    def initialize
      super

      @scene = StartScene.new
    end
  end

  class StartScene < GSDL::Scene
    def initialize
      super(:start)
    end

    def update(frame_time)
    end

    def draw(renderer : SDL3::Renderer)
      # Get the texture dimensions
      player_texture = GSDL::TextureManager.get("player")
      player_width, player_height = player_texture.size

      # Set up a destination rectangle to draw the player in the center of the screen
      dest_rect = SDL3::FRect.new(
        x: (WIDTH - player_width) // 2,
        y: (HEIGHT - player_height) // 2,
        w: player_width,
        h: player_height
      )

      renderer.render_texture(player_texture, dest_rect)
    end
  end

  Game.new.run
end
