require "./text"
require "./rich_text"
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

  class HUDText
    include HUDElement

    record TemplatePart, value : String, is_key : Bool

    @text_data_template : String? = nil
    @template_parts = [] of TemplatePart
    @last_template_values = {} of String => String
    @force_template_update = true

    getter text_element : Text

    def text_data_template; @text_data_template; end

    def text_data_template=(template : String?)
      @text_data_template = template
      parse_template
    end

    def initialize(
      font = Font.default,
      text : String | Text = "",
      text_data_template = nil,
      @anchor = Anchor::TopLeft,
      @offset_x = 0,
      @offset_y = 0,
      origin = {0_f32, 0_f32},
      scale : Num | Tuple(Num, Num) = {1_f32, 1_f32},
      color = ColorScheme.get(:ui_text),
      align = Font::Align::Left,
      z_index = 1000,
      wrap_width = 0
    )
      actual_scale = scale.is_a?(Tuple) ? scale : {scale, scale}

      # Robust check for rich text tags in both source strings
      is_rich = false
      rich_tags = ["<b>", "</b>", "<i>", "</i>", "<c:", "</c>"]

      if text.is_a?(String)
        is_rich ||= rich_tags.any? { |t| text.includes?(t) }
      end

      if text_data_template.is_a?(String)
        is_rich ||= rich_tags.any? { |t| text_data_template.includes?(t) }
      end

      if text.is_a?(Text)
        @text_element = text
      elsif is_rich
        @text_element = RichText.new(
          font: font,
          text: text.is_a?(String) ? text : "",
          origin: origin,
          scale: actual_scale,
          color: color,
          align: align,
          z_index: z_index,
          wrap_width: wrap_width
        )
      else
        @text_element = Text.new(
          font: font,
          text: text.is_a?(String) ? text : "",
          origin: origin,
          scale: actual_scale,
          color: color,
          align: align,
          z_index: z_index,
          wrap_width: wrap_width > 0 ? wrap_width : nil
        )
      end

      @text_element.draw_relative_to_camera = false
      self.text_data_template = text_data_template
    end

    def draw_relative_to_camera=(val : Bool)
      @text_element.draw_relative_to_camera = val
    end

    def draw_relative_to_camera?
      @text_element.draw_relative_to_camera?
    end

    private def parse_template
      @template_parts.clear
      @last_template_values.clear
      @force_template_update = true

      template = @text_data_template
      return if template.nil?

      last_idx = 0
      template.scan(/\{([^}]+)\}/) do |match|
        if match.begin > last_idx
          @template_parts << TemplatePart.new(template[last_idx...match.begin], false)
        end
        key = match[1]
        @template_parts << TemplatePart.new(key, true)
        @last_template_values[key] = ""
        last_idx = match.end
      end

      if last_idx < template.bytesize
        @template_parts << TemplatePart.new(template[last_idx..-1], false)
      end
    end

    def text : String; @text_element.text; end
    def text=(text : String); @text_element.text = text; end
    def color : Color; @text_element.color; end
    def color=(color : Color); @text_element.color = color; end
    def z_index : Int32; @text_element.z_index; end
    def z_index=(z_index : Int32); @text_element.z_index = z_index; end
    def origin : Tuple(Float32, Float32); @text_element.origin; end
    def origin=(origin : Tuple(Float32, Float32)); @text_element.origin = origin; end
    def scale : Tuple(Num, Num); @text_element.scale; end
    def scale=(scale : Tuple(Num, Num)); @text_element.scale = scale; end

    def x : Num; screen_x; end
    def y : Num; screen_y; end

    def hud_update(dt : Float32)
      update(dt)
    end

    def hud_draw(draw : Draw)
      @text_element.x = x
      @text_element.y = y
      @text_element.draw(draw)
    end

    def update(dt : Float32)
      if @text_data_template
        changed = false
        @template_parts.each do |part|
          if part.is_key
            key = part.value
            val = GSDL::Data.get(key).raw
            str_val = case val
                      when String then val
                      when Nil then ""
                      else val.to_s
                      end
            if @last_template_values[key] != str_val
              @last_template_values[key] = str_val
              changed = true
            end
          end
        end

        if changed || @force_template_update
          @force_template_update = false
          new_text = String.build do |io|
            @template_parts.each do |part|
              if part.is_key
                io << @last_template_values[part.value]
              else
                io << part.value
              end
            end
          end
          self.text = new_text if self.text != new_text
        end
      end

      @text_element.update(dt)
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
      background_color = ColorScheme.get(:alt),
      foreground_color = ColorScheme.get(:success),
      border_color = ColorScheme.get(:border),
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
        x: screen_x,
        y: screen_y,
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
      self.x = screen_x
      self.y = screen_y
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

  class HUDPerformance
    include HUDElement
    @update_timer : Float32 = 0_f32
    @hud_text : HUDText

    def initialize(
      font = Font.default,
      @anchor = Anchor::TopLeft,
      @offset_x = 20,
      @offset_y = 20,
      color = ColorScheme.get(:ui_text),
      scale = 0.5_f32,
      align = Font::Align::Left
    )
      @hud_text = HUDText.new(
        font: font,
        anchor: anchor,
        offset_x: offset_x,
        offset_y: offset_y,
        color: color,
        scale: scale,
        align: align
      )
    end

    def text : String; @hud_text.text; end
    def text=(text : String); @hud_text.text = text; end
    def color : Color; @hud_text.color; end
    def color=(color : Color); @hud_text.color = color; end
    def z_index : Int32; @hud_text.z_index; end
    def z_index=(z_index : Int32); @hud_text.z_index = z_index; end
    def origin : Tuple(Float32, Float32); @hud_text.origin; end
    def origin=(origin : Tuple(Float32, Float32)); @hud_text.origin = origin; end
    def scale : Tuple(Num, Num); @hud_text.scale; end
    def scale=(scale : Tuple(Num, Num)); @hud_text.scale = scale; end

    def x : Num; screen_x; end
    def y : Num; screen_y; end

    def hud_update(dt : Float32)
      @hud_text.anchor = @anchor
      @hud_text.offset_x = @offset_x
      @hud_text.offset_y = @offset_y
      @hud_text.update(dt)

      @update_timer += dt
      return if @update_timer < 0.1_f32
      @update_timer = 0_f32

      metrics = [
        "FPS: #{GSDL::Game.fps}",
        "Cmds: #{GSDL::Game.draw.command_count}",
        "Flushes: #{GSDL::Game.draw.flush_count}"
      ]
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

    def hud_draw(draw : Draw)
      @hud_text.hud_draw(draw)
    end
  end
end
