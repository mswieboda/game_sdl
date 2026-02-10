module GSDL
  module Gfx
    class TileMap
      # Using a 2D array of Int32 to store global tile IDs.
      property map_data : Array(Array(Int32))
      # Map of tileset key to Tileset object
      property tilesets : Hash(String, Tileset)
      property tile_width : Int32
      property tile_height : Int32
      property map_width_tiles : Int32
      property map_height_tiles : Int32

      def initialize(@tile_width, @tile_height)
        @map_data = [] of Array(Int32)
        @tilesets = {} of String => Tileset
        @map_width_tiles = 0
        @map_height_tiles = 0
      end

      # Adds a tileset to the map with a given key
      def add_tileset(key : String, tileset : Tileset)
        @tilesets[key] = tileset
      end

      # Loads map data from a simple 2D array for demonstration
      def load_map_data(data : Array(Array(Int32)))
        @map_data = data
        @map_height_tiles = data.size
        @map_width_tiles = data.empty? ? 0 : data[0].size
      end

      # Translates a global_gid into a Tileset and its local_tile_id
      def find_tileset_and_local_id(global_gid : Int32) : TileInfo?
        # A global_gid of 0 typically means an empty tile in Tiled
        return nil if global_gid == 0

        @tilesets.each do |key, tileset|
          if tileset.contains_gid?(global_gid)
            local_tile_id = global_gid - tileset.first_gid
            return TileInfo.new(key, local_tile_id)
          end
        end
        nil # No tileset found for this global_gid
      end

      # Draws the tilemap
      def draw(renderer : SDL3::Renderer, camera_x : Int32, camera_y : Int32)
        # Implement frustum culling here
        # For simplicity, drawing all tiles for now.

        @map_data.each_with_index do |row_data, y_index|
          row_data.each_with_index do |global_gid, x_index|
            tile_info = find_tileset_and_local_id(global_gid)
            next unless tile_info

            tileset = @tilesets[tile_info.tileset_key]
            next unless tileset # Should not happen if find_tileset_and_local_id returns TileInfo

            src_rect = tileset.get_local_tile_src_rect(tile_info.local_tile_id)
            dest_rect = SDL3::FRect.new(
              x: x_index * @tile_width - camera_x,
              y: y_index * @tile_height - camera_y,
              w: @tile_width,
              h: @tile_height
            )

            renderer.render_texture(tileset.texture, src_rect, dest_rect)
          end
        end
      end
    end
  end
end
