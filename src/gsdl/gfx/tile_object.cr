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

    def update(dt : Float32)
    end

    def contains?(px : Float32, py : Float32) : Bool
      get_collision_rect.in?(px.to_f32, py.to_f32)
    end

    # Returns the collision rectangle for this object.
    # Subclasses should override this if they have a different collision box.
    def get_collision_rect : FRect
      if @gid
        # Tiled tile objects have origin at bottom-left
        FRect.new(@x, @y - @height, @width, @height)
      else
        # Tiled rect objects have origin at top-left
        FRect.new(@x, @y, @width, @height)
      end
    end
  end
end


