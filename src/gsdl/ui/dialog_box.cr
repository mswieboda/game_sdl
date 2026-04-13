module GSDL
  class DialogBox
    getter current_node : DialogNode?
    getter is_active : Bool = false
    getter selected_choice : Int32 = 0
    getter style : DialogStyle
    property? draw_relative_to_camera : Bool = false

    # UI Elements
    @main_box : Message
    @main_text : TextBase
    @choices_boxes : Array(Message) = [] of Message
    @valid_choices : Array(DialogChoice) = [] of DialogChoice
    @show_choices : Bool = false

    # Callbacks
    @on_action : Proc(String, Void)? = nil
    @on_condition : Proc(String, Bool)? = nil

    delegate z_index, to: @main_box

    def initialize(
      @style : DialogStyle = DialogStyle.classic_rpg,
      on_action : Proc(String, Void)? = nil,
      on_condition : Proc(String, Bool)? = nil,
      z_index : Int32 = 900,
      draw_relative_to_camera : Bool = false
    )
      @draw_relative_to_camera = draw_relative_to_camera
      @on_action = on_action
      @on_condition = on_condition

      @main_text = TextTyped.new(
        text: "",
        color: @style.color,
        type: TextTyped::Type::Word,
        on_complete: -> { @show_choices = true }
      )

      @main_box = Message.new(
        text: @main_text,
        x: @style.x,
        y: @style.y,
        origin: @style.origin,
        width: @style.width,
        height: @style.height,
        color: @style.color,
        bg_color: @style.bg_color,
        border_radius: @style.border_radius,
        z_index: z_index,
        draw_relative_to_camera: draw_relative_to_camera
      )

      @main_text.draw_relative_to_camera = draw_relative_to_camera
    end

    def z_index=(z_index : Int32)
      @main_box.z_index = z_index
      @choices_boxes.each do |box|
        box.z_index = z_index
      end
    end

    def on_action(&callback : String -> Void)
      @on_action = callback
    end

    def on_condition(&callback : String -> Bool)
      @on_condition = callback
    end

    def start(node_id : String)
      @is_active = true
      load_node(node_id)
    end

    def stop
      @is_active = false
      @current_node = nil
    end

    private def check_condition(condition : String) : Bool
      @on_condition.try &.call(condition) || false
    end

    private def execute_action(action : String)
      @on_action.try &.call(action)
    end

    private def load_node(node_id : String)
      if node_id == "exit"
        stop
        return
      end

      node = DialogManager.get_node(node_id)
      if node.nil?
        puts "Error: Dialog node '#{node_id}' not found."
        stop
        return
      end

      @current_node = node
      @selected_choice = 0
      @show_choices = false
      if main_t = @main_text.as?(TextTyped)
        main_t.full_text = node.text
      elsif main_t = @main_text.as?(RichTextTyped)
        main_t.text = node.text
        main_t.restart
      end

      # Build choice boxes
      @choices_boxes.clear
      if choices = node.choices
        # Filter choices by conditions
        @valid_choices = choices.select do |choice|
          conditions = choice.conditions
          if conditions
            conditions.all? { |cond| check_condition(cond) }
          else
            true
          end
        end

        y_offset = @style.choices_y
        @valid_choices.each_with_index do |choice, i|
          # Add a prefix for unselected choices initially
          text = "#{@style.unselected_prefix}#{choice.text}"

          box = Message.new(
            text: text,
            x: @style.choices_x,
            y: y_offset,
            origin: @style.choices_origin,
            width: @style.choice_width,
            height: @style.choice_height,
            color: @style.choice_color,
            bg_color: @style.choice_bg_color,
            border_radius: @style.choice_border_radius,
            draw_relative_to_camera: self.draw_relative_to_camera?
          )
          box.z_index = @main_box.z_index
          @choices_boxes << box

          # If spacing is provided, use it. Otherwise, use box height + some small default.
          # Here we assume choice_spacing is the total vertical step.
          # If choice_spacing is small (e.g. < box height), we ensure we at least move by box height.
          y_offset += {@style.choice_spacing, box.height.to_f32 + 4.0_f32}.max
        end
      else
        @valid_choices = [] of DialogChoice
      end
    end

    private def select_current_choice
      return if @valid_choices.empty?

      choice = @valid_choices[@selected_choice]

      # Execute actions if any
      if actions = choice.actions
        actions.each { |action| execute_action(action) }
      end

      # Move to next node
      load_node(choice.next_id)
    end

    def update(dt : Float32)
      return unless @is_active

      @main_box.update(dt)

      # Allow skipping typing text
      if !@show_choices && Input.action?(:menu_select)
        if (t = @main_text).responds_to?(:complete)
          t.complete
        end
        @show_choices = true
        return # Consume input
      end

      return unless @show_choices
      return if @valid_choices.empty?

      # Handle input
      if Input.action?(:menu_up)
        @selected_choice -= 1
        @selected_choice = 0 if @selected_choice < 0
      elsif Input.action?(:menu_down)
        max_choice = [@valid_choices.size - 1, 0].max
        @selected_choice += 1
        @selected_choice = max_choice if @selected_choice > max_choice
      elsif Input.action?(:menu_select)
        select_current_choice
      end

      # Update visual selection
      @choices_boxes.each_with_index do |box, i|
        choice = @valid_choices[i]
        if i == @selected_choice
          box.text = "#{@style.selected_prefix}#{choice.text}"
        else
          box.text = "#{@style.unselected_prefix}#{choice.text}"
        end
      end
    end

    def draw(draw : Draw)
      return unless @is_active

      @main_box.draw(draw)

      if @show_choices
        @choices_boxes.each &.draw(draw)
      end
    end
  end
end
