module GSDL
  # Represents information about a specific tile, including its tileset and local ID.
  struct TileInfo
    property tileset_key : String
    property local_tile_id : Int32
    property? solid : Bool

    def initialize(@tileset_key, @local_tile_id, @solid)
    end
  end
end
