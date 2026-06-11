require "./container"
require "./button"
require "./text"

module GSDL
  module UI
    class DropdownMenuList < Container
      getter dropdown : Dropdown

      def initialize(
        @dropdown : Dropdown,
        options : Array(String),
        x : Int32,
        y : Int32,
        width : Int32,
        height : Int32,
        background_color : Color,
        hover_background_color : Color,
        text_color : Color
      )
        @x = x
        @y = y
        @width = width
        @height = height
        @background_color = background_color
        @clips_children = false
        @swallows_events = true

        # Create option buttons and position them vertically
        options.each_with_index do |opt, idx|
          btn = Button.new(
            text: opt,
            width: FillParent,
            height: height,
            default_background_color: background_color,
            hover_background_color: hover_background_color,
            default_text_color: text_color,
            hover_text_color: text_color,
            h_align: HorizontalAlign::Left,
            padding: Spacing.new(horizontal: 12, vertical: 0)
          ) do
            @dropdown.selected_index = idx
            @dropdown.close_menu!
          end

          btn.x = 0
          btn.y = idx * height
          btn.width = width
          btn.height = height
          add_child(btn)
        end
      end

      def contains_point?(mx : Int32, my : Int32) : Bool
        return false unless visible?
        @children.any?(&.contains_point?(mx, my))
      end
    end

    class Dropdown < Container
      property? opened : Bool = false
      property options : Array(String)
      getter selected_index : Int32
      property on_change : Proc(String, Int32, Nil)? = nil

      property header_background_color : Color
      property list_background_color : Color
      property hover_background_color : Color
      property text_color : Color

      @header : Button
      @menu_list : DropdownMenuList? = nil

      def initialize(
        @options : Array(String),
        initial_index : Int32 = 0,
        @width : Int32 = FillParent,
        @height : Int32 = 32,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::TopLeft,
        header_background_color : Color | String = "#1e1e24",
        list_background_color : Color | String = "#121214",
        hover_background_color : Color | String = "#4f46e5",
        text_color : Color | String = "#f4f4f5",
        @on_change : Proc(String, Int32, Nil)? = nil,
        @padding = Spacing.new(all: 0),
        @margin = Spacing.new(all: 0),
        @flex : UInt8 = 1_u8,
      )
        @selected_index = initial_index.clamp(0, @options.size - 1)
        @header_background_color = header_background_color.is_a?(String) ? Color.parse(header_background_color) : header_background_color
        @list_background_color = list_background_color.is_a?(String) ? Color.parse(list_background_color) : list_background_color
        @hover_background_color = hover_background_color.is_a?(String) ? Color.parse(hover_background_color) : hover_background_color
        @text_color = text_color.is_a?(String) ? Color.parse(text_color) : text_color

        @clips_children = false
        @swallows_events = true

        # Create header button
        selected_text = @options.empty? ? "" : @options[@selected_index]
        @header = Button.new(
          text: selected_text,
          width: FillParent,
          height: FillParent,
          default_background_color: @header_background_color,
          hover_background_color: @hover_background_color,
          default_text_color: @text_color,
          hover_text_color: @text_color,
          h_align: HorizontalAlign::Left,
          padding: Spacing.new(top: 0, right: 32, bottom: 0, left: 12)
        ) do
          toggle_menu!
        end

        add_child(@header)
      end

      def selected_option : String?
        @options[@selected_index]?
      end

      def selected_index=(index : Int32)
        return if index == @selected_index
        @selected_index = index.clamp(0, @options.size - 1)
        update_header_text
        @on_change.try(&.call(selected_option.not_nil!, @selected_index))
      end

      def options=(new_options : Array(String))
        @options = new_options
        @selected_index = @selected_index.clamp(0, @options.size - 1)
        update_header_text
        if @opened
          close_menu!
          open_menu!
        end
      end

      private def toggle_menu!
        if @opened
          close_menu!
        else
          open_menu!
        end
      end

      private def update_header_text
        @header.text = selected_option || ""
      end

      def open_menu!
        return if @opened
        @opened = true
        update_header_text

        # 1. Translate local position to global screen position
        gx, gy = self.global_position

        # 2. Align option list directly below the button bounds
        menu_y = gy + self.height

        # 3. Create absolute-positioned overlay list
        @menu_list = DropdownMenuList.new(
          dropdown: self,
          options: @options,
          x: gx,
          y: menu_y,
          width: self.width,
          height: self.height, # Individual button height equals closed dropdown height
          background_color: @list_background_color,
          hover_background_color: @hover_background_color,
          text_color: @text_color
        )

        # 4. Escalate the child to the unclipped RootCanvas overlays
        if root = find_root_canvas
          root.push_overlay(@menu_list.not_nil!)
        else
          # Fallback when there's no RootCanvas
          if fallback_root = find_highest_non_flow_container || find_highest_container
            @menu_list.not_nil!.z_index = 1000 # High z-index to overlay on top
            
            local_x = gx - fallback_root.unscaled_content_x
            local_y = menu_y - fallback_root.unscaled_content_y
            @menu_list.not_nil!.x = local_x
            @menu_list.not_nil!.y = local_y
            
            fallback_root.add_child(@menu_list.not_nil!)
          else
            # No parent container at all, add directly to self
            @menu_list.not_nil!.x = 0
            @menu_list.not_nil!.y = self.height
            add_child(@menu_list.not_nil!)
          end
        end
        dirty_layout!
      end

      def close_menu!
        return unless @opened
        @opened = false
        update_header_text

        if menu = @menu_list
          if root = find_root_canvas
            root.remove_overlay(menu)
          else
            if fallback_root = find_highest_non_flow_container || find_highest_container
              fallback_root.remove_child(menu)
            else
              remove_child(menu)
            end
          end
        end
        @menu_list = nil
        dirty_layout!
      end

      def contains_point?(mx : Int32, my : Int32) : Bool
        return false unless visible?
        # Only hit test the header because option buttons are self-contained in overlay list
        @header.contains_point?(mx, my)
      end

      def width : Int32
        case @width
        when FillParent
          if p = @parent
            return p.width_fixed? ? (p.width - @margin.horizontal - @padding.horizontal) : 0
          end
          0
        when FitContent
          150
        else
          @width
        end
      end

      def height : Int32
        case @height
        when FillParent
          if p = @parent
            return p.height_fixed? ? (p.height - @margin.vertical - @padding.vertical) : 0
          end
          0
        when FitContent
          @header.height
        else
          @height
        end
      end

      def layout!
        return if @children.empty?

        # Reset and layout header
        @header.reset_layout!
        @header.width = self.width
        @header.height = self.style_height > 0 ? self.style_height : 32
        @header.layout!

        @dirty_layout = false
      end

      def update(dt : Float32)
        @header.update(dt)
      end

      def draw(draw : Draw)
        super(draw)

        # Draw the triangle arrow on top of the header button
        arrow_w = 10
        arrow_h = 6
        arrow_x = content_x + content_width - 24
        arrow_y = content_y + (content_height - arrow_h) // 2

        if opened?
          offset_x = arrow_x - arrow_w // 2
          Triangle.new(
            x1: offset_x + arrow_w // 2, y1: arrow_y,
            x2: offset_x, y2: arrow_y + arrow_h,
            x3: offset_x + arrow_w, y3: arrow_y + arrow_h,
            color: @text_color,
            z_index: effective_z_index + 2,
            draw_mode: Shape::DrawMode::Fill
          ).draw(draw)
        else
          Triangle.new(
            x1: arrow_x, y1: arrow_y,
            x2: arrow_x + arrow_w, y2: arrow_y,
            x3: arrow_x + arrow_w // 2, y3: arrow_y + arrow_h,
            color: @text_color,
            z_index: effective_z_index + 2,
            draw_mode: Shape::DrawMode::Fill
          ).draw(draw)
        end
      end
    end
  end
end
