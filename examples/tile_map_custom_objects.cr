require "../src/game_sdl"

module TileMapCustomEx
  WIDTH = 800
  HEIGHT = 600

  # 1. Define custom TileObject subclasses
  class Chest < GSDL::TileObject
    @open : Bool = false

    # Override get_collision_rect to provide custom collision size
    def get_collision_rect : GSDL::FRect
      # Let's say chests are smaller than their tile size (32x32)
      # and we want the collision to be at the bottom center.
      GSDL::FRect.new(@x + 4, @y - 20, 24, 20)
    end

    def interact : String
      @open = !@open
      "Chest is now #{@open ? "OPEN" : "CLOSED"}"
    end

    def update(dt : Float32)
      # Custom logic here (e.g. animation)
    end
  end

  class NPC < GSDL::TileObject
    def get_collision_rect : GSDL::FRect
      # NPCs might have a tall but narrow collision box
      GSDL::FRect.new(@x + 8, @y - @height, 16, @height)
    end

    def interact : String
      "NPC '#{@name}' says: Hello there!"
    end
  end

  # ... (factory registration and Game class stay the same)
  GSDL::TileObjectFactory.register_class("chest", Chest)
  GSDL::TileObjectFactory.register_class("npc", NPC)

  class Game < GSDL::Game
    def initialize
      super(title: "Custom Tile Objects Example")
        end

    def init
      GSDL::Events.esc_exits = true
      GSDL::Game.push(MainScene.new)
        end

    def load_textures
      [{"tiles", "gfx/tiles.png"}]
    end

    def load_default_font
      "fonts/PressStart2P.ttf"
    end
  end

  class MainScene < GSDL::Scene
    @tile_map : GSDL::TileMap
    @player_rect : GSDL::FRect = GSDL::FRect.new(100, 100, 32, 32)
    @help_text : GSDL::Text
    @interaction_text : GSDL::Text
    @display_timer : Float32 = 0.0_f32

    def initialize
      super(:main)

      @help_text = GSDL::Text.new(text: "WASD to move, E to interact", x: 10, y: 10)
      @interaction_text = GSDL::Text.new(text: "", x: (WIDTH/2).to_f32, y: (HEIGHT - 50).to_f32, origin: {0.5_f32, 0.5_f32}, color: GSDL::Color::Yellow)

      # Load or create a map
      texture = GSDL::TextureManager.get("tiles")
      tileset = GSDL::Tileset.new(texture, 32, 32, first_gid: 1)
      @tile_map = GSDL::TileMap.new(32, 32)
      @tile_map.add_tileset("tiles", tileset)

      # Create some objects manually (usually these come from TMX/JSON)
      objects = [] of GSDL::TileObject

      # A chest object
      objects << GSDL::TileObjectFactory.create(
        id: 1, name: "Gold Chest", type: "chest",
        x: 160, y: 160, width: 32, height: 32,
        rotation: 0, visible: true, gid: 1.to_u32, properties: {} of String => JSON::Any
      )

      # An NPC object
      objects << GSDL::TileObjectFactory.create(
        id: 2, name: "Villager", type: "npc",
        x: 300, y: 200, width: 32, height: 32,
        rotation: 0, visible: true, gid: 2.to_u32, properties: {} of String => JSON::Any
      )

      obj_group = GSDL::ObjectGroup.new("entities", objects)
      @tile_map.layers << obj_group
    end

    def update(dt : Float32)
      @tile_map.update(dt)

      # Update display timer for interaction text
      if @display_timer > 0
        @display_timer -= dt
        @interaction_text.text = "" if @display_timer <= 0
      end

      # Simple movement for the "player" rect
      speed = 200 * dt
      @player_rect.x += speed if GSDL::Keys.pressed?(GSDL::Keys::D)
      @player_rect.x -= speed if GSDL::Keys.pressed?(GSDL::Keys::A)
      @player_rect.y += speed if GSDL::Keys.pressed?(GSDL::Keys::S)
      @player_rect.y -= speed if GSDL::Keys.pressed?(GSDL::Keys::W)

      # Interaction check
      if GSDL::Keys.just_pressed?(GSDL::Keys::E)
        # Check for objects in a slightly larger area around player
        interact_rect = GSDL::FRect.new(@player_rect.x - 10, @player_rect.y - 10, @player_rect.w + 20, @player_rect.h + 20)
        nearby_objects = @tile_map.get_objects_in(interact_rect)

        nearby_objects.each do |obj|
          if obj.is_a?(Chest)
            @interaction_text.text = obj.interact
            @display_timer = 2.0_f32 # Show for 2 seconds
          elsif obj.is_a?(NPC)
            @interaction_text.text = obj.interact
            @display_timer = 3.0_f32 # Show for 3 seconds
          end
        end
      end

      @help_text.update(dt)
      @interaction_text.update(dt)
    end

    def draw(draw : GSDL::Draw)
      @tile_map.draw(draw)

      # Draw player
      draw.rect_fill(@player_rect, GSDL::Color.new(0, 255, 0, 100))

      # Visualize collision boxes of objects
      @tile_map.objects.each do |obj|
        # Check if player center is inside object collision box
        color = obj.contains?(@player_rect.x + @player_rect.w/2, @player_rect.y + @player_rect.h/2) ? GSDL::Color::Red : GSDL::Color::Cyan
        draw.rect_outline(obj.get_collision_rect, color)
      end

      @help_text.draw(draw)
      @interaction_text.draw(draw) if !@interaction_text.text.empty?
    end
  end

  Game.new.run
end
