require "./text"

module GSDL
  class ScrollTextView
    include Centerable
    include Tweenable

    property x : Num
    property y : Num
    property width : Int32
    property height : Int32
    property scroll_offset : Float32 = 0_f32
    property padding : Int32 = 8
    property scroll_speed : Float32 = 40.0_f32
    property z_index : Int32 = 0
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    getter tweens : Array(Tween) = [] of Tween

    property scroll_up_action : Symbol = :scroll_up
    property scroll_down_action : Symbol = :scroll_down
    property scroll_keyboard_speed : Float32 = 300.0_f32
    property mouse_scroll_enabled : Bool = true
    property mouse_scroll_reversed : Bool = false

    property show_scrollbar : Bool = true
    property scrollbar_width : Int32 = 4
    property scrollbar_color : Color = Color::Gray
    property scrollbar_padding : Int32 = 2
    
    @text : Text

    def initialize(
      font = Font.default,
      text : String = "",
      @width = 200,
      @height = 200,
      @x = 0,
      @y = 0,
      @origin = {0_f32, 0_f32},
      color = Color::White,
      @padding = 8,
      @z_index = 0,
      @scale = {1_f32, 1_f32}
    )
      @text = Text.new(
        font: font,
        text: text,
        color: color,
        wrap_width: @width - @padding * 2,
        z_index: @z_index
      )
    end

    def scale_x : Num; scale[0]; end
    def scale_y : Num; scale[1]; end

    def scale_x=(scale_x : Num)
      self.scale = {scale_x, scale_y}
    end

    def scale_y=(scale_y : Num)
      self.scale = {scale_x, scale_y}
    end

    def scale=(scale : Num)
      self.scale = {scale, scale}
    end

    def scale=(scale : Tuple(Num, Num))
      @scale = scale
      @text.scale = scale
    end

    def x=(x : Num); @x = x; end
    def y=(y : Num); @y = y; end
    def z_index=(z_index : Int32); @z_index = z_index; @text.z_index = z_index; end

    def text=(text : String)
      @text.text = text
    end

    def color=(color : Color)
      @text.color = color
    end

    def content_height
      @text.height + padding * 2
    end

    def update(dt : Float32)
      update_tweens(dt)
      @text.update(dt)

      # Handle scrolling
      if @mouse_scroll_enabled && Mouse.in?(draw_x, draw_y, draw_width, draw_height)
        # Mouse wheel works if enabled and over the view
        multiplier = @mouse_scroll_reversed ? -1.0_f32 : 1.0_f32
        @scroll_offset -= Mouse.wheel_y * scroll_speed * multiplier
      end

      # Keyboard/Action scrolling
      if Input.action?(scroll_up_action)
        @scroll_offset -= scroll_keyboard_speed * dt
      end
      if Input.action?(scroll_down_action)
        @scroll_offset += scroll_keyboard_speed * dt
      end

      # Clamp scroll offset
      max_scroll = Math.max(0_f32, content_height.to_f32 - height)
      @scroll_offset = @scroll_offset.clamp(0_f32, max_scroll)
    end

    def draw(draw : Draw)
      old_clip = draw.clip_rect
      
      # Set clipping to the viewport
      draw.clip_rect = GSDL::Rect.new(draw_x.to_i, draw_y.to_i, draw_width.to_i, draw_height.to_i)
      
      # Position text relative to viewport
      @text.x = draw_x + padding
      @text.y = draw_y + padding - @scroll_offset
      @text.draw(draw)

      draw.clip_rect = old_clip

      draw_scrollbar(draw) if @show_scrollbar
    end

    private def draw_scrollbar(draw : Draw)
      ch = content_height
      return if ch <= height

      # Calculate thumb height
      view_ratio = height.to_f32 / ch
      thumb_h = (height * view_ratio).clamp(20_f32, height.to_f32)

      # Calculate thumb Y position
      scroll_ratio = @scroll_offset / (ch - height)
      thumb_y = draw_y + scroll_ratio * (height - thumb_h)

      # Draw scrollbar on the right
      draw.rect_fill(
        rect: FRect.new(
          x: draw_x + draw_width - scrollbar_width - scrollbar_padding,
          y: thumb_y,
          w: scrollbar_width.to_f32,
          h: thumb_h
        ),
        color: scrollbar_color,
        z_index: @z_index + 1
      )
    end

    def origin_x : Float32; origin[0]; end
    def origin_y : Float32; origin[1]; end
    def draw_width : Num; width; end
    def draw_height : Num; height; end
    def draw_x : Num; x - (draw_width * origin_x); end
    def draw_y : Num; y - (draw_height * origin_y); end
  end
end
