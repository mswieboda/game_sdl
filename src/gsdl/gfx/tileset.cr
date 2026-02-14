module GSDL
  class Tileset
    property texture : SDL3::Texture
    property tile_width : Int32
    property tile_height : Int32
    property columns : Int32
    property rows : Int32
    property first_gid : Int32 # The first global ID this tileset represents
    property solid_tiles : Array(Int32)

    def initialize(@texture, @tile_width, @tile_height, @first_gid = 1)
      texture_width_f, texture_height_f = @texture.size
      texture_width = texture_width_f.to_i
      texture_height = texture_height_f.to_i

      @columns = texture_width // @tile_width
      @rows = texture_height // @tile_height
      @solid_tiles = [] of Int32
    end

    def solid?(local_tile_id : Int32) : Bool
      @solid_tiles.includes?(local_tile_id)
    end

    # Returns the source rectangle for a LOCAL tile ID within this tileset
    def get_local_tile_source_rect(local_tile_id : Int32) : FRect
      x = (local_tile_id % @columns) * @tile_width
      y = (local_tile_id // @columns) * @tile_height

      FRect.new(x: x, y: y, w: @tile_width, h: @tile_height)
    end

    # The number of tiles in this tileset
    def tile_count : Int32
      @columns * @rows
    end

    # Checks if a global_gid belongs to this tileset
    def contains_gid?(global_gid : Int32) : Bool
      global_gid >= @first_gid && global_gid < (@first_gid + tile_count)
    end
  end
end
