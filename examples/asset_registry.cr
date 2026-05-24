require "../src/game_sdl"

# 1. Map assets on startup (No loading happens here, enums and paths are registered)
GSDL::TextureManager.register({
  player: "ship.png",
  tiles: "tiles.png",
  barrel: "barrel.png",
  palm_tree: "palm-tree.png"
})

GSDL::FontManager.register({
  press_start_2p: "PressStart2P.ttf"
})

GSDL::AudioManager.register({
  coin: "ding.wav"
})

GSDL::TileMapManager.register({
  map: "map.json"
})

module GameEx
  class AssetRegistryGame < GSDL::Game
    def initialize
      super(title: "Asset Registry & Lazy Weak Cache Ex", width: 800, height: 600, high_pixel_density: true)
    end

    def init
      GSDL::Events.esc_exits = true

      puts "--- STAGE 1: Asset Registration (Startup) ---"
      puts "Assets mapped and registered successfully via macros. No textures, fonts, sounds or maps are loaded yet!"

      # Check compile-time type safety comment:
      # Un-commenting the line below will throw a compile error because of an invalid enum:
      # GSDL::TextureManager.get(.invalid_texture)

      GSDL::Game.push(DemoScene.new)
    end
  end

  class DemoScene < GSDL::Scene
    @text : GSDL::Text? = nil
    @sprite : GSDL::Sprite? = nil
    @audio : GSDL::Audio? = nil
    @tile_map : GSDL::TileMap? = nil

    @state = :idle
    @timer = 0_f32

    def initialize
      super(:demo)
    end

    def init
      puts "\n--- STAGE 2: Lazy Loading ---"
      puts "Requesting and allocating Font: .PressStart2P (Lazy Loading...)"
      @text = GSDL::Text.new(font: :press_start_2p, text: "Lazy Cache Demo\n\n1. Lazy loaded assets on-demand\n2. Deleting references...\n3. GC and pruning...\n4. Reload check", color: GSDL::Color::White)
      @text.not_nil!.x = 50
      @text.not_nil!.y = 50

      puts "Requesting and allocating Texture: .Player (Lazy Loading...)"
      @sprite = GSDL::Sprite.new(:player)
      @sprite.not_nil!.x = 400
      @sprite.not_nil!.y = 300

      puts "Requesting and allocating Audio: .CoinAudio (Lazy Loading...)"
      @audio = GSDL::Audio.new(:coin)

      puts "Requesting and allocating TileMap: .Map (Lazy Loading...)"
      @tile_map = GSDL::TileMapManager.get(:map)

      puts "All requested assets loaded lazily successfully!"
      @audio.not_nil!.play
    end

    def update(dt : Float32)
      @timer += dt
      @sprite.try(&.update(dt))
      @text.try(&.update(dt))

      case @state
      when :idle
        if @timer > 1.5_f32
          puts "\n--- STAGE 3: Deleting References & GC ---"
          puts "Releasing all references to the sprite, texture, and audio..."
          @sprite = nil
          @audio = nil
          @tile_map = nil

          puts "Running Garbage Collector (GC.collect)..."
          GC.collect

          puts "Pruning dead weak references from Managers..."
          GSDL::TextureManager.prune_dead_references
          GSDL::AudioManager.prune_dead_references
          GSDL::TileMapManager.prune_dead_references

          @state = :gc_done
        end
      when :gc_done
        if @timer > 3.0_f32
          puts "\n--- STAGE 4: Reload Verification ---"
          puts "Requesting the Texture: .Player again. It should reload cleanly!"
          @sprite = GSDL::Sprite.new(key: :player)
          @sprite.not_nil!.x = 400
          @sprite.not_nil!.y = 350
          puts "Texture reloaded and allocated cleanly!"

          puts "\nRequesting the Audio: .CoinAudio again. It should reload cleanly!"
          @audio = GSDL::Audio.new(:coin)
          @audio.not_nil!.play
          puts "Audio reloaded cleanly and playing!"

          @state = :finished
        end
      when :finished
        if @timer > 4.5_f32
          puts "\n--- SUCCESS: All stages completed perfectly! Exiting... ---"
          GSDL::Game.quit!
        end
      end
    end

    def draw_camera_view(draw : GSDL::Draw)
      @text.try(&.draw(draw))
      @sprite.try(&.draw(draw))
    end
  end

  AssetRegistryGame.new.run
end
