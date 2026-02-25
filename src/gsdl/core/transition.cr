module GSDL
  enum TransitionDirection
    In
    Out
  end

  abstract class Transition
    getter direction : TransitionDirection
    getter? done : Bool = false
    getter? started : Bool = false
    property duration : Float32
    @timer : Float32 = 0_f32

    def initialize(@direction : TransitionDirection, @duration = 1_f32, @started = false)
    end

    def running?
      started? && !done?
    end

    def ran?
      started? && done?
    end

    def start
      @started = true
    end

    def clear
      @started = false
      @timer = 0_f32
    end

    def continue
      @done = true
    end

    def update(dt : Float32)
      @timer += dt
      if @timer >= @duration
        @timer = @duration
        continue
      end
    end

    def progress
      @timer / @duration
    end

    abstract def draw(draw : Draw)
  end

  class EmptyTransition < Transition
    def initialize
      super(direction: TransitionDirection::In, duration: 0_f32)
    end

    def draw(draw : Draw)
    end
  end

  class FadeTransition < Transition
    @color : Color

    def initialize(direction : TransitionDirection, duration = 1.0_f32, started = false, @color = Color::Black)
      super(direction: direction, duration: duration, started: started)
    end

    def draw(draw : Draw)
      alpha = if direction.in?
        # Fade in: 1.0 -> 0.0 alpha (revealing scene)
        (1.0_f32 - progress) * 255
      else
        # Fade out: 0.0 -> 1.0 alpha (hiding scene)
        progress * 255
      end
      
      # Use Game global values
      w, h = {Game.width.to_f32, Game.height.to_f32}
      
      c = @color
      c.a = alpha.to_u8

      draw.rect_fill(FRect.new(w: w, h: h), color: c, z_index: 1000)
    end
  end

  class SquareTransition < Transition
    @color : Color
    @grid_size : Int32
    @squares : Array(Tuple(Int32, Int32))

    def initialize(direction : TransitionDirection, duration = 1.0_f32, started = false, @color = Color::Black, @grid_size = 64)
      super(direction: direction, duration: duration, started: started)
      
      @squares = [] of Tuple(Int32, Int32)
      cols = Game.width // @grid_size + 1
      rows = Game.height // @grid_size + 1
      
      cols.times do |x|
        rows.times do |y|
          @squares << {x, y}
        end
      end

      @squares.shuffle!
    end

    def draw(draw : Draw)
      # In transition: squares disappear (reveal)
      # Out transition: squares appear (hide)
      
      total_squares = @squares.size
      visible_count = if direction.in?
        # Disappearing: from total to 0
        ((1.0_f32 - progress) * total_squares).to_i
      else
        # Appearing: from 0 to total
        (progress * total_squares).to_i
      end

      visible_count.times do |i|
        x_idx, y_idx = @squares[i]
        draw.rect_fill(
          FRect.new(
            x: x_idx * @grid_size,
            y: y_idx * @grid_size,
            w: @grid_size
          ),
          color: @color,
          z_index: 1000
        )
      end
    end
  end
end
