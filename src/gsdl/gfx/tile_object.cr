module GSDL
  class TileObject
    property id : Int32
    property name : String
    property type : String # or class
    property x : Float32
    property y : Float32
    property width : Float32
    property height : Float32
    property rotation : Float32
    property visible : Bool
    property gid : UInt32?
    property properties : Hash(String, JSON::Any)

    def initialize(
      @id,
      @name,
      @type,
      @x,
      @y,
      @width,
      @height,
      @rotation = 0.0_f32,
      @visible = true,
      @gid = nil,
      @properties = {} of String => JSON::Any
    )
    end
  end
end


