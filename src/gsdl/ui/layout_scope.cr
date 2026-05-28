module GSDL
  module UI
    struct LayoutScope
      def initialize(@parent : Container)
      end

      # Macro to register standard components (no nested layout blocks).
      # If a block is passed, it is forwarded as a callback (e.g. for Button on_click).
      macro register_component(method_name, klass)
        def {{method_name}}(*args, **kwargs)
          child = {{klass}}.new(*args, **kwargs)
          @parent.layout_add_child(child)
          child
        end

        def {{method_name}}(*args, **kwargs, &block)
          child = {{klass}}.new(*args, **kwargs, &block)
          @parent.layout_add_child(child)
          child
        end
      end

      # Macro to register container components that take nested layout blocks.
      macro register_container(method_name, klass)
        def {{method_name}}(*args, **kwargs, &)
          child = {{klass}}.new(*args, **kwargs)
          @parent.layout_add_child(child)
          scope = LayoutScope.new(child)
          with scope yield
          child
        end

        def {{method_name}}(*args, **kwargs)
          child = {{klass}}.new(*args, **kwargs)
          @parent.layout_add_child(child)
          child
        end
      end

      # Define our DSL elements cleanly:
      register_component text, Text
      register_component image, Image
      register_component button, Button
      register_component checkbox, Checkbox
      register_component radio_button, RadioButton
      register_component dropdown, Dropdown

      register_container vbox, VBox
      register_container hbox, HBox
      register_container canvas, Canvas
      register_container viewport, Viewport
      register_container status_bar, StatusBar
    end
  end
end
