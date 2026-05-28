require "./container"
require "./button"
require "./text"

module GSDL
  module UI
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
      @option_buttons = Array(Button).new

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
        @on_change : Proc(String, Int32, Nil)? = nil
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
          text: selected_text + "  ▼",
          width: FillParent,
          height: FillParent,
          default_background_color: @header_background_color,
          hover_background_color: @hover_background_color,
          default_text_color: @text_color,
          hover_text_color: @text_color,
          h_align: HorizontalAlign::Left,
          padding: Spacing.new(horizontal: 12, vertical: 0)
        ) do
          toggle_menu!
        end

        add_child(@header)

        # Build list of options buttons
        rebuild_option_buttons!
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
        rebuild_option_buttons!
        update_header_text
      end

      private def toggle_menu!
        @opened = !@opened
        if @opened
          @just_opened = true
          # Reset all option buttons' backgrounds so they don't carry over stale hover states!
          @option_buttons.each do |btn|
            btn.background_color = @list_background_color
            btn.label.color = @text_color
          end
        end
        @header.text = (selected_option || "") + (@opened ? "  ▲" : "  ▼")
        rebuild_children!
        dirty_layout!
      end

      private def update_header_text
        @header.text = (selected_option || "") + (@opened ? "  ▲" : "  ▼")
      end

      private def rebuild_option_buttons!
        @option_buttons.clear
        @options.each_with_index do |opt, idx|
          btn = create_option_button(opt, idx)
          # Set high z-index relative to layout so option list floats on top
          btn.z_index = 1000
          @option_buttons << btn
        end
        rebuild_children!
      end

      private def create_option_button(opt : String, idx : Int32) : Button
        Button.new(
          text: opt,
          width: FillParent,
          height: @header.height,
          default_background_color: @list_background_color,
          hover_background_color: @hover_background_color,
          default_text_color: @text_color,
          hover_text_color: @text_color,
          h_align: HorizontalAlign::Left,
          padding: Spacing.new(horizontal: 12, vertical: 0)
        ) do
          self.selected_index = idx
          toggle_menu!
        end
      end


      private def rebuild_children!
        clear_children
        add_child(@header)
        if @opened
          @option_buttons.each do |btn|
            add_child(btn)
          end
        end
      end

      def contains_point?(mx : Int32, my : Int32) : Bool
        return false unless visible?

        # Always check header
        return true if @header.contains_point?(mx, my)

        # If opened, check all option buttons
        if @opened
          @option_buttons.each do |btn|
            return true if btn.contains_point?(mx, my)
          end
        end

        false
      end

      def width : Int32
        # Dropdown layout width is solely based on style/header size
        case @width
        when FillParent
          if p = @parent
            return p.width_fixed? ? (p.width - @margin.horizontal - @padding.horizontal) : 0
          end
          0
        when FitContent
          # Minimum default width for dropdown
          150
        else
          @width
        end
      end

      def height : Int32
        # Dropdown layout height remains the closed header height
        # so it doesn't push down other elements in a VBox/HBox when opened
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

        if @opened
          current_y = @header.height
          @option_buttons.each do |btn|
            btn.reset_layout!
            btn.x = 0
            btn.y = current_y
            btn.width = @header.width
            btn.height = @header.height
            btn.layout!
            current_y += btn.footprint_height
          end
        end

        @dirty_layout = false
      end

      def update(dt : Float32)
        # Manually update children to prevent same-frame array mutation & double click issues
        @header.update(dt)

        if @opened
          if @just_opened
            # Position all child elements correctly immediately so they are in position for the next frame
            layout!
            @just_opened = false
            # On the frame it was opened, we explicitly skip updating option buttons.
            # This guarantees they cannot receive the same-frame mouse click/press event.
          else
            @option_buttons.each do |btn|
              btn.update(dt)
            end
          end
        end

        # Detect click outside to close the menu
        if @opened && GSDL::Mouse.just_pressed?(GSDL::Mouse::ButtonLeft)
          unless contains_point?(GSDL::Mouse.x, GSDL::Mouse.y)
            toggle_menu!
          end
        end
      end

      # Prevent external manipulation of children for Dropdown
      private def add_child(child : Element)
        super(child)
      end

      @[Deprecated("Directly removing children from a Dropdown is forbidden and will break layout.")]
      def remove_child(child : Element)
        super(child)
      end

      @[Deprecated("Clearing children of a Dropdown is forbidden and will break layout.")]
      def clear_children
        super
      end
    end
  end
end
