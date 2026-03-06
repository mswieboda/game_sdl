require "json"

module GSDL
  alias TileObjectCreator = Proc(
    Int32,             # id
    String,            # name
    String,            # type
    Float32,           # x
    Float32,           # y
    Float32,           # width
    Float32,           # height
    Float32,           # rotation
    Bool,              # visible
    UInt32?,           # gid
    Hash(String, JSON::Any), # properties
    TileObject
  )

  class TileObjectFactory
    @@creators = {} of String => TileObjectCreator

    def self.register(type : String, creator : TileObjectCreator)
      @@creators[type] = creator
    end

    # Macro to make registration easier
    macro register_class(type, klass)
      GSDL::TileObjectFactory.register({{type}}, ->(id : Int32, name : String, type : String, x : Float32, y : Float32, width : Float32, height : Float32, rotation : Float32, visible : Bool, gid : UInt32?, properties : Hash(String, JSON::Any)) {
        {{klass}}.new(id, name, type, x, y, width, height, rotation, visible, gid, properties).as(GSDL::TileObject)
      })
    end

    def self.create(
      id : Int32,
      name : String,
      type : String,
      x : Float32,
      y : Float32,
      width : Float32,
      height : Float32,
      rotation : Float32,
      visible : Bool,
      gid : UInt32?,
      properties : Hash(String, JSON::Any)
    ) : TileObject
      if creator = @@creators[type]?
        creator.call(id, name, type, x, y, width, height, rotation, visible, gid, properties)
      else
        TileObject.new(id, name, type, x, y, width, height, rotation, visible, gid, properties)
      end
    end
  end
end
