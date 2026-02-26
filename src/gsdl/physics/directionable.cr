module GSDL
  enum Direction
    Up
    UpRight
    Right
    DownRight
    Down
    DownLeft
    Left
    UpLeft

    # Cardinal Aliases
    North = Up
    South = Down
    East  = Right
    West  = Left

    # Ordinal Aliases
    NorthEast = UpRight
    NorthWest = UpLeft
    SouthEast = DownRight
    SouthWest = DownLeft
  end

  module Directionable
    # requires
    abstract def draw_x : Num
    abstract def draw_y : Num

    property direction = Direction::Down

    def facing?(x : Num, y : Num) : Bool
      dx = x - draw_x
      dy = y - draw_y

      case direction
      when .up?
        dy < 0
      when .down?
        dy > 0
      when .left?
        dx < 0
      when .right?
        dx > 0
      # TODO: test these combo cases, see if they make sense
      # as they are pretty opinionated
      when .up_right?
        dy < 0 && dx > 0
      when .up_left?
        dy < 0 && dx < 0
      when .down_right?
        dy > 0 && dx > 0
      when .down_left?
        dy > 0 && dx < 0
      else false
      end
    end
  end
end
