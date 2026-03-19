require "../gfx/geo/box"
require "./text"

module GSDL
  class TabContainer
    include Tweenable

    alias TabChangedCallback = (Int32) ->

    property x : Num = 0
    property y : Num = 0
    property width : Num = 400
    property height : Num = 300
    property tab_height : Num = 40
    property active_index : Int32 = 0

    property background_color : Color = GSDL.color(r: 30, g: 30, b: 30, a: 220)
    property tab_color : Color = Color::DarkGray
    property active_tab_color : Color = Color::Gray
    property text_color : Color = Color::White
    property border_color : Color = Color::White

    property z_index : Int32 = 0
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}

    property on_tab_changed : TabChangedCallback?
    getter? changed : Bool = true

    @tabs : Array(String)
    @tab_texts : Array(Text)
    @tab_rects : Array(FRect) = [] of FRect

    getter tweens : Array(Tween) = [] of Tween

    def initialize(
      @tabs = [] of String,
      @x = 0,
      @y = 0,
      @width = 400,
      @height = 300,
      @tab_height = 40,
      @active_index = 0,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @on_tab_changed = nil,
      @z_index = 0
    )
      @tab_texts = @tabs.map do |name|
        Text.new(
          text: name,
          color: text_color,
          origin: {0.5_f32, 0.5_f32},
          z_index: @z_index + 2
        )
      end
      calculate_layout
    end

    def draw_width : Num
      width * scale_x
    end

    def draw_height : Num
      height * scale_y
    end

    def draw_x : Num
      x - (draw_width * origin_x)
    end

    def draw_y : Num
      y - (draw_height * origin_y)
    end

    def origin_x : Float32
      origin[0]
    end

    def origin_y : Float32
      origin[1]
    end

    def scale_x : Num
      scale[0]
    end

    def scale_y : Num
      scale[1]
    end

    def scale_x=(scale_x : Num)
      self.scale = {scale_x, scale_y}
    end

    def scale_y=(scale_y : Num)
      self.scale = {scale_x, scale_y}
    end

    private def calculate_layout
      return if @tabs.empty?

      @tab_rects.clear
      tab_w = draw_width / @tabs.size

      @tabs.each_with_index do |_, i|
        tx = draw_x + (i * tab_w)
        ty = draw_y
        @tab_rects << FRect.new(x: tx.to_f32, y: ty.to_f32, w: tab_w.to_f32, h: (tab_height * scale_y).to_f32)

        @tab_texts[i].x = tx + (tab_w / 2)
        @tab_texts[i].y = ty + (tab_height * scale_y / 2)
        @tab_texts[i].scale = {scale_x.to_f32, scale_y.to_f32}
        @tab_texts[i].z_index = z_index + 2
      end
    end

    def update(dt : Float32)
      update_tweens(dt)
      calculate_layout if changed? # Basic check, though usually we don't change every frame

      if Mouse.just_pressed?(Mouse::ButtonLeft)
        @tab_rects.each_with_index do |rect, i|
          if Mouse.in?(rect.x, rect.y, rect.w, rect.h)
            if @active_index != i
              @active_index = i
              @on_tab_changed.try &.call(i)
            end
            break
          end
        end
      end

      @tab_texts.each(&.update(dt))
    end

    def draw(draw : GSDL::Draw)
      # Content Background
      content_y = draw_y + (tab_height * scale_y)
      content_h = draw_height - (tab_height * scale_y)

      bg = Box.new(
        width: width, height: height - tab_height,
        x: x, y: y + tab_height,
        color: background_color,
        origin: origin,
        scale: scale,
        z_index: z_index,
        border_radius: 8,
        border_thickness: 2,
        border_color: border_color
      )
      bg.draw(draw)

      # Tabs
      @tab_rects.each_with_index do |rect, i|
        is_active = (i == active_index)

        t_box = Box.new(
          width: rect.w / scale_x,
          height: rect.h / scale_y,
          x: rect.x + (rect.w / 2),
          y: rect.y + (rect.h / 2),
          color: is_active ? active_tab_color : tab_color,
          origin: {0.5_f32, 0.5_f32},
          scale: scale,
          z_index: z_index + 1,
          border_radius: 4,
          border_thickness: is_active ? 2 : 1,
          border_color: border_color
        )
        t_box.draw(draw)
        @tab_texts[i].draw(draw)
      end
    end
  end
end
