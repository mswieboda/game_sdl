require "./spacing"

module GSDL
  module UI
    FillParent = -2
    FitContent = -1

    abstract class Element
      # Basic Transform
      getter x : Int32 = 0
      getter y : Int32 = 0

      getter width : Int32 = FitContent
      getter height : Int32 = FitContent

      # The Box Model
      property margin : Spacing = Spacing.new(all: 0)
      property padding : Spacing = Spacing.new(all: 0)

      # The "Shares" this element takes in a BoxLayout
      # 0 = Fixed/Fit, 1+ = Flex Fill
      getter flex : UInt8 = 1_u8

      # Aesthetics
      property background_color : Color?
      property foreground_color : Color = Color::White

      # Layout Logic (For things like Bottom Bar alignment)
      getter anchor : Anchor = Anchor::TopLeft
      property z_index : Int32 = 0

      def effective_z_index : Int32
        if p = @parent
          p.effective_z_index + 1 + @z_index
        else
          @z_index
        end
      end

      # Tree Structure
      property? visible : Bool = true
      property parent : Element?
      property? swallows_events : Bool = false

      # Hover State & Callbacks
      property hover_cursor : GSDL::SystemCursor? = nil
      property on_hover_enter : Proc(Element, Nil)? = nil
      property on_hover_leave : Proc(Element, Nil)? = nil
      getter? hovered : Bool = false

      def hovered=(value : Bool)
        return if @hovered == value
        @hovered = value
        if value
          @on_hover_enter.try(&.call(self))
        else
          @on_hover_leave.try(&.call(self))
        end
      end

      @dirty_position : Bool = true
      @global_position_cache : {Int32, Int32} = {0, 0}

      def draw(draw : Draw)
        return unless visible?
        draw_background(draw)
      end

      def update(dt : Float32)
      end

      def contains_point?(mx : Int32, my : Int32) : Bool
        return false unless visible?
        mx >= inner_x && mx < (inner_x + inner_width) && my >= inner_y && my < (inner_y + inner_height)
      end

      def find_element_at(mx : Int32, my : Int32) : Element?
        return nil unless visible? && (contains_point?(mx, my) || (self.is_a?(Container) && !self.clips_children?))

        if self.is_a?(Container)
          self.children.sort_by(&.effective_z_index).reverse_each do |child|
            if found = child.find_element_at(mx, my)
              return found
            end
          end
        end

        if contains_point?(mx, my)
          self
        else
          nil
        end
      end

      def on_mouse_down(event : GSDL::Event) : Bool
        swallows_events?
      end

      def on_mouse_up(event : GSDL::Event) : Bool
        swallows_events?
      end

      def on_mouse_move(event : GSDL::Event) : Bool
        swallows_events?
      end

      def on_mouse_wheel(event : GSDL::Event) : Bool
        swallows_events?
      end

      def draw_background(draw : Draw)
        if (color = @background_color) && !color.transparent?
          draw.rect_fill(
            rect: FRect.new(
              x: inner_x,
              y: inner_y,
              w: inner_width,
              h: inner_height,
            ),
            color: color,
            z_index: effective_z_index,
          )
        end
      end

      def x=(x : Int32)
        return if @x == x
        @x = x
        @style_x = x
        dirty_position!
      end

      def y=(y : Int32)
        return if @y == y
        @y = y
        @style_y = y
        dirty_position!
      end

      @style_x : Int32?
      @style_y : Int32?

      def style_x : Int32
        @style_x ||= @x
      end

      def style_y : Int32
        @style_y ||= @y
      end

      @style_width : Int32?
      @style_height : Int32?

      def style_width : Int32
        @style_width ||= @width
      end

      def style_height : Int32
        @style_height ||= @height
      end

      def reset_layout!
        if style_width == FitContent || style_width == FillParent
          self.width = style_width
        end
        if style_height == FitContent || style_height == FillParent
          self.height = style_height
        end
      end

      def width=(width : Int32)
        return if @width == width
        @width = width
        @style_width = width
        dirty_position!
        dirty_layout!
      end

      def height=(height : Int32)
        return if @height == height
        @height = height
        @style_height = height
        dirty_position!
        dirty_layout!
      end

      def set_layout_width(width : Int32)
        return if @width == width
        @width = width
        dirty_position!
        dirty_layout!
      end

      def set_layout_height(height : Int32)
        return if @height == height
        @height = height
        dirty_position!
        dirty_layout!
      end

      def anchor=(anchor : Anchor)
        return if @anchor == anchor
        @anchor = anchor

        # When the anchor changes, we re-calculate our local x/y
        if p = @parent
          # This sets our internal @x and @y based on the new anchor
          apply_anchor!(p.width, p.height)
        end

        dirty_position!
      end

      def flex=(flex : UInt8)
        return if @flex == flex
        @flex = flex
        if p = @parent
          dirty_layout! if p.is_a?(Container)
        end
      end

      protected def dirty_position!
        @dirty_position = true
      end

      protected def dirty_layout!
        # Base implementation does nothing
      end

      protected def dirty_position? : Bool
        @dirty_position || (@parent && @parent.not_nil!.dirty_position?) || false
      end

      def width_fixed? : Bool
        # It's fixed if it's a specific number OR if it's the RootCanvas
        return true if style_width > 0 || self.is_a?(RootCanvas)

        # If I am a fill parent, I am only fixed if my parent is fixed
        if style_width == FillParent && (p = @parent)
          return p.width_fixed?
        end

        false
      end

      def height_fixed? : Bool
        # It's fixed if it's a specific number OR if it's the RootCanvas
        return true if style_height > 0 || self.is_a?(RootCanvas)

        # If I am a fill parent, I am only fixed if my parent is fixed
        if style_height == FillParent && (p = @parent)
          return p.height_fixed?
        end

        false
      end

      def apply_anchor!(pw : Int32, ph : Int32)
        # Skip if we are being managed by a BoxLayout (since BoxLayout sequences positions)
        if p = @parent
          return if p.is_a?(BoxLayout)
        end

        off_x, off_y = calculate_anchor_offset(pw, ph)

        # Update local x/y. These will be added to the parent's content_x/y
        # in the global_position call.
        @x = off_x + style_x
        @y = off_y + style_y
      end

      # Ancestor Helper (protected, so subclasses of Element can access, but hidden from public API)
      protected def viewport_ancestor : Viewport?
        p = @parent
        while p
          if p.is_a?(Viewport)
            return p
          end
          p = p.parent
        end
        nil
      end

      protected def root_canvas : RootCanvas?
        curr = self
        while curr
          if curr.is_a?(RootCanvas)
            return curr
          end
          curr = curr.parent
        end
        nil
      end

      def find_root_canvas : RootCanvas?
        root_canvas
      end

      def find_highest_container : Container?
        curr = self.parent
        highest : Container? = nil
        while curr
          if curr.is_a?(Container)
            highest = curr
          end
          curr = curr.parent
        end
        highest
      end

      def find_highest_non_flow_container : Container?
        curr = self.parent
        highest : Container? = nil
        while curr
          if curr.is_a?(Container) && !curr.is_a?(BoxLayout)
            highest = curr
          end
          curr = curr.parent
        end
        highest
      end

      def is_descendant_of_overlay? : Bool
        curr = self
        while curr
          if p = curr.parent
            if p.is_a?(RootCanvas)
              return p.overlays.includes?(curr)
            end
          end
          curr = curr.parent
        end
        false
      end

      def is_descendant_of?(other : Element) : Bool
        curr = self.parent
        while curr
          return true if curr == other
          curr = curr.parent
        end
        false
      end

      private def update_position_cache
        if dirty_position?
          @global_position_cache = calculate_global_position
          @dirty_position = false
        end
      end

      # Unscaled coordinates and dimensions (protected, for internal layout and nested coordinate composition)
      protected def unscaled_global_position : {Int32, Int32}
        update_position_cache
        @global_position_cache
      end

      protected def unscaled_global_x : Int32
        unscaled_global_position[0]
      end

      protected def unscaled_global_y : Int32
        unscaled_global_position[1]
      end

      protected def unscaled_inner_position : {Int32, Int32}
        ugx, ugy = unscaled_global_position
        {ugx + @margin.left, ugy + @margin.top}
      end

      protected def unscaled_inner_x : Int32
        unscaled_inner_position[0]
      end

      protected def unscaled_inner_y : Int32
        unscaled_inner_position[1]
      end

      protected def unscaled_content_position : {Int32, Int32}
        uix, uiy = unscaled_inner_position
        {uix + @padding.left, uiy + @padding.top}
      end

      protected def unscaled_content_x : Int32
        unscaled_content_position[0]
      end

      protected def unscaled_content_y : Int32
        unscaled_content_position[1]
      end

      protected def unscaled_inner_width : Int32
        width + @padding.horizontal
      end

      protected def unscaled_inner_height : Int32
        height + @padding.vertical
      end

      protected def unscaled_content_width : Int32
        width
      end

      protected def unscaled_content_height : Int32
        height
      end

      def calculate_global_position : {Int32, Int32}
        # Start with local relative offset
        base_x = self.x
        base_y = self.y

        if (p = @parent).nil?
          return {base_x, base_y}
        end

        # We must use unscaled content_x/y of parent so layout coordinates remain stable and unscaled
        {p.unscaled_content_x + base_x, p.unscaled_content_y + base_y}
      end

      # Public coordinate API (automatically virtualized when inside a Viewport)
      def global_position : {Int32, Int32}
        {global_x, global_y}
      end

      def global_x : Int32
        if vp = viewport_ancestor
          rel_x = unscaled_global_x - vp.unscaled_content_x
          (vp.unscaled_content_x + (rel_x + vp.pan_x) * vp.zoom).to_i
        else
          unscaled_global_x
        end
      end

      def global_y : Int32
        if vp = viewport_ancestor
          rel_y = unscaled_global_y - vp.unscaled_content_y
          (vp.unscaled_content_y + (rel_y + vp.pan_y) * vp.zoom).to_i
        else
          unscaled_global_y
        end
      end

      def inner_position : {Int32, Int32}
        {inner_x, inner_y}
      end

      def inner_x : Int32
        if vp = viewport_ancestor
          rel_x = unscaled_inner_x - vp.unscaled_content_x
          (vp.unscaled_content_x + (rel_x + vp.pan_x) * vp.zoom).to_i
        else
          unscaled_inner_x
        end
      end

      def inner_y : Int32
        if vp = viewport_ancestor
          rel_y = unscaled_inner_y - vp.unscaled_content_y
          (vp.unscaled_content_y + (rel_y + vp.pan_y) * vp.zoom).to_i
        else
          unscaled_inner_y
        end
      end

      def inner_width : Int32
        if vp = viewport_ancestor
          (unscaled_inner_width * vp.zoom).to_i
        else
          unscaled_inner_width
        end
      end

      def inner_height : Int32
        if vp = viewport_ancestor
          (unscaled_inner_height * vp.zoom).to_i
        else
          unscaled_inner_height
        end
      end

      def content_x : Int32
        if vp = viewport_ancestor
          rel_x = unscaled_content_x - vp.unscaled_content_x
          (vp.unscaled_content_x + (rel_x + vp.pan_x) * vp.zoom).to_i
        else
          unscaled_content_x
        end
      end

      def content_y : Int32
        if vp = viewport_ancestor
          rel_y = unscaled_content_y - vp.unscaled_content_y
          (vp.unscaled_content_y + (rel_y + vp.pan_y) * vp.zoom).to_i
        else
          unscaled_content_y
        end
      end

      def content_width : Int32
        if vp = viewport_ancestor
          (unscaled_content_width * vp.zoom).to_i
        else
          unscaled_content_width
        end
      end

      def content_height : Int32
        if vp = viewport_ancestor
          (unscaled_content_height * vp.zoom).to_i
        else
          unscaled_content_height
        end
      end

      def layout!
        # Base implementation does nothing
      end

      def footprint_x : Int32
        global_x
      end

      def footprint_y : Int32
        global_y
      end

      # The total horizontal space taken up in the parent
      def footprint_width : Int32
        inner_width + @margin.horizontal
      end

      # The total horizontal space taken up in the parent
      def footprint_height : Int32
        inner_height + @margin.vertical
      end

      private def calculate_anchor_offset(parent_width : Int32, parent_height : Int32) : {Int32, Int32}
        # The "Footprint" is the total space this element occupies in its parent.
        # Using the 'inner' dimensions (Padding+Content) + the Margins.
        footprint_width = self.inner_width + @margin.horizontal
        footprint_height = self.inner_height + @margin.vertical

        x_offset = case @anchor
        when .top_left?, .center_left?, .bottom_left?
          0
        when .top_center?, .center?, .bottom_center?
          # Centers the entire footprint within the parent width
          (parent_width - footprint_width) // 2
        when .top_right?, .center_right?, .bottom_right?
          # Snaps the right edge of the margin to the parent's right edge
          parent_width - footprint_width
        else
          0
        end

        y_offset = case @anchor
        when .top_left?, .top_center?, .top_right?
          0
        when .center_left?, .center?, .center_right?
          (parent_height - footprint_height) // 2
        when .bottom_left?, .bottom_center?, .bottom_right?
          parent_height - footprint_height
        else
          0
        end

        {x_offset, y_offset}
      end
    end
  end
end
