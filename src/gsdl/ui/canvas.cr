require "./container"

module GSDL
  module UI
    class Canvas < Container
      def initialize(
        @width : Int32 = FillParent,
        @height : Int32 = FillParent,
        @x : Int32 = 0,
        @y : Int32 = 0,
        @anchor : Anchor = Anchor::Center,
        @background_color : Color = Color::Transparent,
        padding : SpacingInput = 0,
        margin : SpacingInput = 0,
        @flex : UInt8 = 0_u8,
      )
        self.padding = padding
        self.margin = margin
      end
    end

    class RootCanvas < Canvas
      OVERLAY_BASE_Z_INDEX = 1000

      getter overlays = Array(Element).new
      @current_hover_path = Array(Element).new
      @default_cursor : GSDL::Cursor? = nil
      getter focused_element : Element? = nil

      def focused_element=(element : Element?)
        return if @focused_element == element
        old_focused = @focused_element
        @focused_element = element

        # Notify elements of focus state change
        if old_focused && old_focused.responds_to?(:on_unfocus)
          old_focused.on_unfocus
        end
        if element && element.responds_to?(:on_focus)
          element.on_focus
        end
      end

      def initialize(@width : Int32, @height : Int32)
        super(
          width: width,
          height: height,
          x: 0,
          y: 0,
          anchor: Anchor::TopLeft
        )
      end

      def push_overlay(element : Element)
        element.parent = self
        element.z_index = OVERLAY_BASE_Z_INDEX
        @overlays << element unless @overlays.includes?(element)
      end

      def remove_overlay(element : Element)
        element.parent = nil if element.parent == self
        @overlays.delete(element)
      end

      def clear_overlays
        @overlays.each do |overlay|
          if overlay.is_a?(DropdownMenuList)
            overlay.dropdown.close_menu!
          end
        end
        @overlays.clear
      end

      def clear_overlays_except_for(target : Element?)
        to_remove = [] of Element
        @overlays.each do |overlay|
          if overlay.is_a?(DropdownMenuList)
            if target && (target == overlay.dropdown || target.is_descendant_of?(overlay.dropdown))
              next
            end
            overlay.dropdown.close_menu!
          else
            to_remove << overlay
          end
        end
        to_remove.each { |o| @overlays.delete(o) }
      end

      # The Root is the end of the line, it returns its own x,y (0,0)
      def global_position : {Int32, Int32}
        @dirty_position = false # Clear the flag so the ripple stops
        {@x, @y}
      end

      # Critical: Update this when the user resizes the window
      def resize(width : Int32, height : Int32)
        self.width = width
        self.height = height
      end

      def draw(draw : Draw)
        # Phase 1: Draw regular UI layout tree with standard clipping
        super(draw)

        # Phase 2: Draw absolute-positioned overlays on top of everything unclipped
        @overlays.each do |overlay|
          overlay.draw(draw) if overlay.visible?
        end
      end

      def update(dt : Float32)
        super(dt)
        @overlays.each &.update(dt)

        update_hover_states
      end

      private def update_hover_states
        # 1. Determine which element is currently under the mouse
        target = find_element_at(GSDL::Mouse.x, GSDL::Mouse.y)

        # 2. Build the new hover path (from leaf to root)
        new_path = [] of Element
        curr = target
        while curr
          new_path << curr
          curr = curr.parent
        end

        # 3. Transition leave for elements no longer in the path
        @current_hover_path.each do |el|
          unless new_path.includes?(el)
            el.hovered = false
          end
        end

        # 4. Transition enter for new elements in the path
        new_path.each do |el|
          unless @current_hover_path.includes?(el)
            el.hovered = true
          end
        end

        # 5. Keep track of the current hover path
        @current_hover_path = new_path

        # 6. Update system mouse cursor based on the deepest custom cursor definition
        update_cursor_for(new_path)
      end

      private def update_cursor_for(path : Array(Element))
        cursor_style = nil
        path.each do |el|
          if style = el.hover_cursor
            cursor_style = style
            break
          end
        end

        if cursor_style
          sdl_id = cursor_style.to_sdl
          GSDL::Mouse.cursor = GSDL::Cursor.get_system(sdl_id)
        else
          GSDL::Mouse.cursor = get_default_cursor
        end
      end

      private def get_default_cursor : GSDL::Cursor
        @default_cursor ||= begin
          if sdl_cursor = SDL3::Mouse.get_default_cursor
            GSDL::Cursor.new(sdl_cursor)
          else
            GSDL::Cursor.create_system(LibSDL3::SystemCursor::DEFAULT)
          end
        end
      end

      def find_element_at(mx : Int32, my : Int32) : Element?
        # 1. Check overlays in reverse order (highest visual depth first)
        @overlays.reverse_each do |overlay|
          next unless overlay.visible?
          if found = overlay.find_element_at(mx, my)
            return found
          end
        end

        # 2. Fall back to standard container layout hierarchy search
        super(mx, my)
      end

      def on_mouse_down(event : GSDL::Event) : Bool
        # Find the element clicked to handle auto-dismissal and focus
        target = find_element_at(GSDL::Mouse.x, GSDL::Mouse.y)

        # Set focused element
        if target
          curr : Element? = target
          focusable_target : Element? = nil
          while curr
            if curr.focusable?
              focusable_target = curr
              break
            end
            curr = curr.parent
          end

          self.focused_element = focusable_target
        else
          self.focused_element = nil
        end

        if !@overlays.empty?
          if target.nil? || !target.is_descendant_of_overlay?
            # Clicked outside active overlays, dismiss them (with target check to avoid double toggles)
            clear_overlays_except_for(target)
          end
        end

        # Dispatch mouse event: try overlays first
        @overlays.reverse_each do |overlay|
          next unless overlay.visible?
          if overlay.contains_point?(GSDL::Mouse.x, GSDL::Mouse.y)
            return true if overlay.on_mouse_down(event)
          end
        end

        # Try regular layout tree
        super(event)
      end

      def on_mouse_up(event : GSDL::Event) : Bool
        @overlays.reverse_each do |overlay|
          next unless overlay.visible?
          if overlay.contains_point?(GSDL::Mouse.x, GSDL::Mouse.y)
            return true if overlay.on_mouse_up(event)
          end
        end
        super(event)
      end

      def on_mouse_move(event : GSDL::Event) : Bool
        @overlays.reverse_each do |overlay|
          next unless overlay.visible?
          if overlay.contains_point?(GSDL::Mouse.x, GSDL::Mouse.y)
            return true if overlay.on_mouse_move(event)
          end
        end
        super(event)
      end

      def on_mouse_wheel(event : GSDL::Event) : Bool
        @overlays.reverse_each do |overlay|
          next unless overlay.visible?
          if overlay.contains_point?(GSDL::Mouse.x, GSDL::Mouse.y)
            return true if overlay.on_mouse_wheel(event)
          end
        end
        super(event)
      end

      def collect_focusable_elements(elements : Array(Element))
        return unless visible?
        super(elements)
        @overlays.each &.collect_focusable_elements(elements)
      end

      def handle_event(event : GSDL::Event) : Bool
        case event.type
        when GSDL::Events::MouseDown
          on_mouse_down(event)
        when GSDL::Events::MouseUp
          on_mouse_up(event)
        when GSDL::Events::MouseMotion
          on_mouse_move(event)
        when GSDL::Events::MouseWheel
          on_mouse_wheel(event)
        when GSDL::Events::KeyDown
          key = event.key.key
          shift_pressed = Keys.pressed?(Keys::LShift) || Keys.pressed?(Keys::RShift) || (event.key.mod.to_i & 0x0003) != 0

          if key == Keys::Tab
            focusable_elements = [] of Element
            collect_focusable_elements(focusable_elements)

            unless focusable_elements.empty?
              if current_focus = @focused_element
                if idx = focusable_elements.index(current_focus)
                  if shift_pressed
                    next_idx = (idx - 1 + focusable_elements.size) % focusable_elements.size
                  else
                    next_idx = (idx + 1) % focusable_elements.size
                  end
                  self.focused_element = focusable_elements[next_idx]
                else
                  self.focused_element = shift_pressed ? focusable_elements.last : focusable_elements.first
                end
              else
                self.focused_element = shift_pressed ? focusable_elements.last : focusable_elements.first
              end
              return true
            end
          end

          if el = @focused_element
            return el.on_key_down(event)
          end
          false
        when GSDL::Events::KeyUp
          if el = @focused_element
            return el.on_key_up(event)
          end
          false
        when GSDL::Events::TextInput
          if el = @focused_element
            return el.on_text_input(event)
          end
          false
        else
          false
        end
      end
    end
  end
end
