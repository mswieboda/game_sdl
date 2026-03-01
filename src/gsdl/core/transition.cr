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
    property easing : GSDL::MathUtils::Easing = GSDL::MathUtils::Easing::Linear
    @timer : Float32 = 0_f32

    def initialize(@direction : TransitionDirection, @duration = 1_f32, @started = false, @easing = GSDL::MathUtils::Easing::Linear)
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
      GSDL::MathUtils.apply_easing(@timer / @duration, @easing)
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

    def initialize(direction : TransitionDirection, duration = 1.0_f32, started = false, @color = Color::Black, easing = GSDL::MathUtils::Easing::Linear)
      super(direction: direction, duration: duration, started: started, easing: easing)
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

    def initialize(direction : TransitionDirection, duration = 1.0_f32, started = false, @color = Color::Black, @grid_size = 64, easing = GSDL::MathUtils::Easing::Linear)
      super(direction: direction, duration: duration, started: started, easing: easing)
      
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
            w: @grid_size,
            h: @grid_size
          ),
          color: @color,
          z_index: 1000
        )
      end
    end
  end

  class SlideLinesTransition < Transition
    @color : Color
    @line_count : Int32

    def initialize(direction : TransitionDirection, duration = 1.0_f32, started = false, @color = Color::Black, @line_count = 10, easing = GSDL::MathUtils::Easing::Linear)
      super(direction: direction, duration: duration, started: started, easing: easing)
    end

    def draw(draw : Draw)
      w, h = {Game.width.to_f32, Game.height.to_f32}
      line_height = h / @line_count

      @line_count.times do |i|
        current_y = i * line_height
        
        rect_w = if direction.in?
          (1.0_f32 - progress) * w
        else
          progress * w
        end

        x = if i % 2 == 0
          direction.in? ? w - rect_w : 0
        else
          direction.in? ? 0 : w - rect_w
        end

        draw.rect_fill(FRect.new(x: x, y: current_y, w: rect_w, h: line_height), color: @color, z_index: 1000)
      end
    end
  end

  class CircleMaskTransition < Transition
    @color : Color

    def initialize(direction : TransitionDirection, duration = 1.0_f32, started = false, @color = Color::Black, easing = GSDL::MathUtils::Easing::Linear)
      super(direction: direction, duration: duration, started: started, easing: easing)
    end

    def draw(draw : Draw)
      w, h = {Game.width.to_f32, Game.height.to_f32}
      center_x, center_y = {w / 2.0_f32, h / 2.0_f32}
      max_radius = Math.hypot(w, h) / 2.0_f32

      radius = if direction.in?
        progress * max_radius
      else
        (1.0_f32 - progress) * max_radius
      end

      # Draw mask using geometry
      segments = 32
      vertices = [] of Vertex
      indices = [] of Int32

      segments.times do |i|
        angle1 = (i.to_f32 / segments) * 2.0_f32 * Math::PI
        angle2 = ((i + 1).to_f32 / segments) * 2.0_f32 * Math::PI
        
        x1, y1 = {center_x + Math.cos(angle1).to_f32 * radius, center_y + Math.sin(angle1).to_f32 * radius}
        x2, y2 = {center_x + Math.cos(angle2).to_f32 * radius, center_y + Math.sin(angle2).to_f32 * radius}
        
        # Far points (at the edge of a very large bounding box)
        fx1, fy1 = {center_x + Math.cos(angle1).to_f32 * max_radius * 2, center_y + Math.sin(angle1).to_f32 * max_radius * 2}
        fx2, fy2 = {center_x + Math.cos(angle2).to_f32 * max_radius * 2, center_y + Math.sin(angle2).to_f32 * max_radius * 2}
        
        base_idx = vertices.size
        vertices << Vertex.new(Point.new(x1, y1), @color)
        vertices << Vertex.new(Point.new(x2, y2), @color)
        vertices << Vertex.new(Point.new(fx1, fy1), @color)
        vertices << Vertex.new(Point.new(fx2, fy2), @color)
        
        indices << base_idx << base_idx + 1 << base_idx + 2
        indices << base_idx + 1 << base_idx + 3 << base_idx + 2
      end
      
      draw.geometry(vertices: vertices, indices: indices, z_index: 1000)
    end
  end

  class BoxesShrinkTransition < Transition
    @color : Color
    @box_size : Int32

    def initialize(direction : TransitionDirection, duration = 1.0_f32, started = false, @color = Color::Black, @box_size = 16, easing = GSDL::MathUtils::Easing::Linear)
      super(direction: direction, duration: duration, started: started, easing: easing)
    end

    def draw(draw : Draw)
      w, h = {Game.width.to_f32, Game.height.to_f32}
      
      cols = (w / @box_size).ceil.to_i
      rows = (h / @box_size).ceil.to_i

      cols.times do |x|
        rows.times do |y|
          # Each box scales based on its position and progress
          # Simple version: all scale together
          scale = if direction.in?
            (1.0_f32 - progress)
          else
            progress
          end

          next if scale <= 0

          size = @box_size * scale
          offset = (@box_size - size) / 2.0_f32

          draw.rect_fill(
            FRect.new(
              x: x * @box_size + offset,
              y: y * @box_size + offset,
              w: size,
              h: size
            ),
            color: @color,
            z_index: 1000
          )
        end
      end
    end
  end
end
