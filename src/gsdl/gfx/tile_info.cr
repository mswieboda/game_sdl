module GSDL
  # Represents information about a specific tile, including its tileset and local ID.
  struct TileInfo
    property tileset_key : String
    property local_tile_id : Int32
    property? solid : Bool
    property flipped_horizontally : Bool
    property flipped_vertically : Bool

    def initialize(
      @tileset_key,
      @local_tile_id,
      @solid,
      @flipped_horizontally = false,
      @flipped_vertically = false
    )
    end
  end
end
