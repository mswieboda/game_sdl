module GSDL
  module Gfx
    # Represents information about a specific tile, including its tileset and local ID.
    struct TileInfo
      property tileset_key : String
      property local_tile_id : Int32

      def initialize(@tileset_key, @local_tile_id)
      end
    end
  end
end
