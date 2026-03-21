require "./text"
require "./progress_bar"

module GSDL
  enum Anchor
    TopLeft
    TopCenter
    TopRight
    CenterLeft
    Center
    CenterRight
    BottomLeft
    BottomCenter
    BottomRight
  end

  module HUDElement
    abstract def hud_update(dt : Float32)
    abstract def hud_draw(draw : Draw)

    property anchor : Anchor = Anchor::TopLeft
    property offset_x : Num = 0
    property offset_y : Num = 0

    def screen_x : Num
      case anchor
      when .top_left?, .center_left?, .bottom_left?
        offset_x
      when .top_center?, .center?, .bottom_center?
        (GSDL::Game.width / 2.0).to_f32 + offset_x
      when .top_right?, .center_right?, .bottom_right?
        GSDL::Game.width.to_f32 - offset_x
      else
        offset_x
      end
    end

    def screen_y : Num
      case anchor
      when .top_left?, .top_center?, .top_right?
        offset_y
      when .center_left?, .center?, .center_right?
        (GSDL::Game.height / 2.0).to_f32 + offset_y
      when .bottom_left?, .bottom_center?, .bottom_right?
        GSDL::Game.height.to_f32 - offset_y
      else
        offset_y
      end
    end
  end

  class HUD
    property elements : Array(HUDElement) = [] of HUDElement

    def update(dt : Float32)
      @elements.each(&.hud_update(dt))
      update_custom(dt)
    end

    def draw(draw : Draw)
      old_scale = draw.scale
      draw.scale = 1.0_f32
      @elements.each(&.hud_draw(draw))
      draw_custom(draw)
      draw.scale = old_scale
    end

    def update_custom(dt : Float32)
    end

    def draw_custom(draw : Draw)
    end

    def add(element : HUDElement)
      @elements << element
      element
    end

    def <<(element : HUDElement)
      add(element)
    end
  end

  class HUDText < Text
    include HUDElement
    property data_key : String? = nil

    def initialize(
      font = Font.default,
      text = "",
      @data_key = nil,
      @anchor = Anchor::TopLeft,
      @offset_x = 0,
      @offset_y = 0,
      origin = {0_f32, 0_f32},
      scale : Num | Tuple(Num, Num) = {1_f32, 1_f32},
      color = Color::White,
      align = Font::Align::Left,
      z_index = 1000
    )
      actual_scale = scale.is_a?(Tuple) ? scale : {scale, scale}
      super(
        font: font,
        text: text,
        x: 0,
        y: 0,
        origin: origin,
        scale: actual_scale,
        color: color,
        align: align,
        z_index: z_index
      )
      self.draw_relative_to_camera = false
    end

    def x : Num; screen_x; end
    def y : Num; screen_y; end

    def hud_update(dt : Float32)
      update(dt)
    end

    def hud_draw(draw : Draw)
      draw(draw)
    end

    def update(dt : Float32)
      update_tweens(dt)
      if key = @data_key
        val = GSDL::Data.get(key)
        raw = val.raw
        new_text = case raw
                   when String
                     raw
                   when Nil
                     ""
                   else
                     val.to_s
                   end
        self.text = new_text if self.text != new_text
      end
    end
  end

  class HUDProgressBar < ProgressBar
    include HUDElement
    property data_key : String? = nil

    def initialize(
      @data_key = nil,
      @anchor = Anchor::TopLeft,
      @offset_x = 0,
      @offset_y = 0,
      width = 100,
      height = 20,
      value = 0.0_f32,
      background_color = Color::DarkGray,
      foreground_color = Color::Green,
      border_color = Color::White,
      border_width = 1,
      border_radius = 0,
      orientation = Orientation::Horizontal,
      origin = {0_f32, 0_f32},
      scale : Num | Tuple(Num, Num) = {1_f32, 1_f32},
      rotation = 0.0_f32,
      z_index = 1000
    )
      actual_scale = scale.is_a?(Tuple) ? scale : {scale, scale}
      super(
        x: 0,
        y: 0,
        width: width,
        height: height,
        value: value,
        background_color: background_color,
        foreground_color: foreground_color,
        border_color: border_color,
        border_width: border_width,
        border_radius: border_radius,
        orientation: orientation,
        origin: origin,
        scale: actual_scale,
        rotation: rotation,
        z_index: z_index
      )
      self.draw_relative_to_camera = false
    end

    def x : Num; screen_x; end
    def y : Num; screen_y; end

    def hud_update(dt : Float32)
      update(dt)
    end

    def hud_draw(draw : Draw)
      draw(draw)
    end

    def update(dt : Float32)
      update_tweens(dt)
      if key = @data_key
        val = GSDL::Data.get(key)
        if v = val.as_f?
          self.value = v.to_f32
        elsif i = val.as_i?
          self.value = i.to_f32
        end
      end
    end
  end

  class HUDPerformance < HUDText
    @update_timer : Float32 = 0_f32

    def initialize(
      font = Font.default,
      @anchor = Anchor::TopLeft,
      @offset_x = 20,
      @offset_y = 20,
      color = Color::White,
      scale = 0.5_f32,
      align = Font::Align::Left
    )
      super(
        font: font,
        anchor: anchor,
        offset_x: offset_x,
        offset_y: offset_y,
        color: color,
        scale: scale,
        align: align
      )
    end

    def hud_update(dt : Float32)
      update(dt)

      @update_timer += dt
      return if @update_timer < 0.1_f32
      @update_timer = 0_f32

      metrics = ["FPS: #{GSDL::Game.fps}"]
      {
        "update" => "Update",
        "draw" => "Draw",
        "collision" => "Collision",
        "query" => "Queries"
      }.each do |key, label|
        val = GSDL::Data.get("perf_#{key}")
        if v = val.as_f?
          if key == "query"
            metrics << "#{label}: #{v.to_i}"
          else
            metrics << "#{label}: #{v.round(3)}ms"
          end
        elsif v_i = val.as_i?
          if key == "query"
            metrics << "#{label}: #{v_i}"
          else
            metrics << "#{label}: #{v_i.to_f.round(3)}ms"
          end
        else
          # Initialize or show zero if not yet tracked
          if key == "query"
            metrics << "#{label}: 0"
          else
            metrics << "#{label}: 0.000ms"
          end
        end
      end
      self.text = metrics.join("\n")
    end
  end
end
