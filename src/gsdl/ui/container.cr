require "./element"

module GSDL
  module UI
    abstract class Container < Element
      property children = [] of Element

      def self.new(*args, **kwargs)
        obj = allocate
        obj.initialize(*args, **kwargs)
        obj
      end

      def self.new(*args, **kwargs, &)
        obj = allocate
        obj.initialize(*args, **kwargs)
        scope = LayoutScope.new(obj)
        with scope yield
        obj
      end

      macro inherited
        def self.new(*args, **kwargs)
          obj = allocate
          obj.initialize(*args, **kwargs)
          obj
        end

        def self.new(*args, **kwargs, &)
          obj = allocate
          obj.initialize(*args, **kwargs)
          scope = LayoutScope.new(obj)
          with scope yield
          obj
        end
      end


      @dirty_layout = true

      protected def dirty_layout!
        return if @dirty_layout
        @dirty_layout = true

        # Propagate down to children since our layout change affects their dimensions/positions
        @children.each(&.dirty_layout!)

        # if the parent's size depends on this container (FIT_CONTENT),
        # we must also mark the parent as dirty.
        if p = parent
          p.dirty_layout! if p.is_a?(Container)
        end
      end

      def layout_add_child(child : Element)
        add_child(child)
      end

      def add_child(child : Element)
        # 1. Prevent adding the same child twice
        return child if @children.includes?(child)

        # 2. If the child already has a different parent, remove it from there first
        if old_parent = child.parent
          if old_parent.is_a?(Container)
            old_parent.remove_child(child)
          end
        end

        # 3. Set the bidirectional relationship
        child.parent = self

        @children << child

        dirty_position!
        dirty_layout!

        child
      end

      def remove_child(child : Element)
        if @children.delete(child)
          child.parent = nil
        end

        dirty_position!
        dirty_layout!

        child
      end

      # Useful helper to clear a container (like a toolbar)
      def clear_children
        @children.each { |c| c.parent = nil }
        @children.clear

        dirty_position!
        dirty_layout!
      end

      property? clips_children : Bool = true

      def layout!
        @children.each do |child|
          child.apply_anchor!(self.width, self.height)
        end
        @dirty_layout = false
      end

      def draw(draw : Draw)
        return unless visible?
        layout! if @dirty_layout

        draw_background(draw)

        if clips_children?
          draw.push_clip(GSDL::Rect.new(content_x, content_y, content_width, content_height))
          @children.each do |child|
            child.draw(draw) if child.visible?
          end
          draw.pop_clip
        else
          @children.each do |child|
            child.draw(draw) if child.visible?
          end
        end
      end

      def update(dt : Float32)
        super(dt)
        @children.each(&.update(dt))
      end

      def on_mouse_down(event : GSDL::Event) : Bool
        @children.sort_by(&.effective_z_index).reverse_each do |child|
          next unless child.visible?
          if child.contains_point?(GSDL::Mouse.x, GSDL::Mouse.y)
            return true if child.on_mouse_down(event)
          end
        end
        super(event)
      end

      def on_mouse_up(event : GSDL::Event) : Bool
        @children.sort_by(&.effective_z_index).reverse_each do |child|
          next unless child.visible?
          if child.contains_point?(GSDL::Mouse.x, GSDL::Mouse.y)
            return true if child.on_mouse_up(event)
          end
        end
        super(event)
      end

      def on_mouse_move(event : GSDL::Event) : Bool
        @children.sort_by(&.effective_z_index).reverse_each do |child|
          next unless child.visible?
          if child.contains_point?(GSDL::Mouse.x, GSDL::Mouse.y)
            return true if child.on_mouse_move(event)
          end
        end
        super(event)
      end

      def on_mouse_wheel(event : GSDL::Event) : Bool
        @children.sort_by(&.effective_z_index).reverse_each do |child|
          next unless child.visible?
          if child.contains_point?(GSDL::Mouse.x, GSDL::Mouse.y)
            return true if child.on_mouse_wheel(event)
          end
        end
        super(event)
      end

      protected def dirty_position!
        return if @dirty_position

        @dirty_position = true

        # Notify children that their global positions are now invalid
        @children.each(&.dirty_position!)
      end

      def width : Int32
        case @width
        when FillParent
          if p = @parent
            # Only fill if the parent has a concrete size to fill.
            # If the parent is also dynamic (-1 or -2), we must return 0
            # or a base size to break the recursion.
            return p.width_fixed? ? (p.width - @margin.horizontal - @padding.horizontal) : 0
          end

          0
        when FitContent
          return 0 if @children.empty?

          @children.max_of { |c| (c.x + c.footprint_width).as(Int32) }
        else
          @width
        end
      end

      def height : Int32
        case @height
        when FillParent
          if p = @parent
            # Only fill if the parent has a concrete size to fill.
            # If the parent is also dynamic (-1 or -2), we must return 0
            # or a base size to break the recursion.
            return p.height_fixed? ? (p.height - @margin.vertical - @padding.vertical) : 0
          end

          0
        when FitContent
          return 0 if @children.empty?

          @children.max_of { |c| (c.y + c.footprint_height).as(Int32) }
        else
          @height
        end
      end
    end
  end
end
