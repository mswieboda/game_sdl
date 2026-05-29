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
        @padding = Spacing.new(all: 0),
        @margin = Spacing.new(all: 0),
        @flex : UInt8 = 1_u8,
      )
      end
    end

    class RootCanvas < Canvas
      OVERLAY_BASE_Z_INDEX = 1000

      getter overlays = Array(Element).new

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
        # Find the element clicked to handle auto-dismissal
        target = find_element_at(GSDL::Mouse.x, GSDL::Mouse.y)

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
        else
          false
        end
      end
    end
  end
end
