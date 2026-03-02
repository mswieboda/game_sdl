require "./text"

module GSDL
  class Menu
    enum IconPlacement
      Left
      Right
      Both
    end

    property x : Num
    property y : Num
    property selected_index : Int32 = 0
    property items_text : Array(Text)
    property items : Array(Tuple(Symbol, String))
    property origin : Tuple(Float32, Float32) = {0_f32, 0_f32}
    property scale : Tuple(Num, Num) = {1_f32, 1_f32}
    property vertical : Bool = true
    property text_align : Font::Align = Font::Align::Center
    property padding : Num = 0
    property item_padding : Num = 0
    property separation : Num = 0
    property items_disabled : Array(Symbol)
    property disabled_text_color : Color = Color::Gray
    property item_width_same : Bool = true
    property item_height_same : Bool = true
    property mouse_hover : Bool = false
    property hover_text_color : Color
    property z_index : Int32 = 0

    @on_select : Symbol -> Nil
    @selected_text_color : (Int32 -> Color)?
    @text_color : (Int32 -> Color)?
    @default_text_color : Color
    
    @is_selected : (Num, Num, Num, Num -> Bool)
    @is_next : (-> Bool)
    @is_previous : (-> Bool)

    @background_box : Box | SpriteBase | Nil
    @item_box : Box | SpriteBase | Nil
    @selected_box : Box | SpriteBase | Nil
    @disabled_box : Box | SpriteBase | Nil
    @hover_box : Box | SpriteBase | Nil

    @selected_icon : SpriteBase?
    @selected_icon_placement : IconPlacement = IconPlacement::Left

    @max_item_width : Num = 0
    @max_item_height : Num = 0
    @menu_width : Num = 0
    @menu_height : Num = 0
    @hovered_index : Int32? = nil
    
    @item_rects : Array(NamedTuple(x: Num, y: Num, w: Num, h: Num)) = [] of NamedTuple(x: Num, y: Num, w: Num, h: Num)

    def initialize(
      @is_selected : (Num, Num, Num, Num -> Bool),
      @is_next : (-> Bool),
      @is_previous : (-> Bool),
      font : Font = Font.default,
      @items = [] of Tuple(Symbol, String),
      @x : Num = 0,
      @y : Num = 0,
      @origin = {0_f32, 0_f32},
      @scale = {1_f32, 1_f32},
      @selected_index : Int32 = 0,
      @vertical : Bool = true,
      @text_align : Font::Align = Font::Align::Center,
      @background_box = nil,
      @item_box = nil,
      @selected_box = nil,
      @selected_icon = nil,
      @selected_icon_placement = IconPlacement::Left,
      @padding : Num = 0,
      @item_padding : Num = 0,
      @separation : Num = 0,
      @default_text_color : Color = Color::White,
      @text_color = nil,
      @selected_text_color = nil,
      @items_disabled = [] of Symbol,
      @disabled_text_color : Color = Color::Gray,
      @disabled_box = nil,
      @item_width_same : Bool = true,
      @item_height_same : Bool = true,
      @mouse_hover : Bool = false,
      @hover_text_color = Color::White,
      @hover_box = nil,
      @z_index : Int32 = 0,
      @on_select : Symbol -> Nil = ->(s : Symbol) { }
    )
      @items_text = [] of Text
      
      # Create items_text and find max dimensions
      @items.each do |(id, text)|
        text_obj = Text.new(
          font: font,
          text: text,
          align: @text_align
        )
        @items_text << text_obj
        
        w = text_obj.width + @item_padding * 2
        h = text_obj.height + @item_padding * 2
        
        @max_item_width = w if w > @max_item_width
        @max_item_height = h if h > @max_item_height
      end

      calculate_layout
      update_colors
    end

    private def calculate_layout
      total_items = @items_text.size
      return if total_items == 0

      # Pre-calculate widths/heights for each item
      item_ws = @items_text.map { |item| @item_width_same ? @max_item_width : item.width + @item_padding * 2 }
      item_hs = @items_text.map { |item| @item_height_same ? @max_item_height : item.height + @item_padding * 2 }

      if @vertical
        @menu_width = item_ws.max + @padding * 2
        @menu_height = item_hs.sum(0_f32) + (@separation * (total_items - 1)) + @padding * 2
      else
        @menu_width = item_ws.sum(0_f32) + (@separation * (total_items - 1)) + @padding * 2
        @menu_height = item_hs.max + @padding * 2
      end

      # Calculate starting position based on origin
      start_x = @x - (@menu_width * scale_x * origin[0])
      start_y = @y - (@menu_height * scale_y * origin[1])

      current_pos_x = start_x + @padding * scale_x
      current_pos_y = start_y + @padding * scale_y

      @item_rects = [] of NamedTuple(x: Num, y: Num, w: Num, h: Num)

      @items_text.each_with_index do |item, index|
        w = item_ws[index] * scale_x
        h = item_hs[index] * scale_y
        
        rect = {x: current_pos_x, y: current_pos_y, w: w, h: h}
        @item_rects << rect

        # Align text within its item slot
        # Text object's internal x, y should be relative to its slot
        case @text_align
        when Font::Align::Left
          item.x = current_pos_x + @item_padding * scale_x
        when Font::Align::Center
          item.x = current_pos_x + (w / 2)
          item.origin = {0.5_f32, item.origin_y}
        when Font::Align::Right
          item.x = current_pos_x + w - @item_padding * scale_x
          item.origin = {1.0_f32, item.origin_y}
        end

        item.y = current_pos_y + (h / 2)
        item.origin = {item.origin_x, 0.5_f32}
        
        item.scale = @scale
        item.z_index = @z_index

        if @vertical
          current_pos_y += h + @separation * scale_y
        else
          current_pos_x += w + @separation * scale_x
        end
      end
    end

    def update(dt : Float32)
      # Handle input
      if @is_previous.call
        move_selection(-1)
      elsif @is_next.call
        move_selection(1)
      end

      if @mouse_hover
        @hovered_index = nil
        @item_rects.each_with_index do |rect, index|
          next if disabled?(@items[index][0])
          if Mouse.in?(rect[:x], rect[:y], rect[:w], rect[:h])
            @hovered_index = index
            break
          end
        end
      end

      # Get current selected item rect for the select proc
      if @selected_index >= 0 && @selected_index < @item_rects.size
        if icon = @selected_icon
          icon.update(dt)
        end

        rect = @item_rects[@selected_index]
        if @is_selected.call(rect[:x], rect[:y], rect[:w], rect[:h])
          unless disabled?(@items[@selected_index][0])
            @on_select.call(@items[@selected_index][0])
          end
        end

        if hovered_index = @hovered_index
          rect = @item_rects[hovered_index]
          if @is_selected.call(rect[:x], rect[:y], rect[:w], rect[:h])
            unless disabled?(@items[hovered_index][0])
              @selected_index = hovered_index
              @on_select.call(@items[hovered_index][0])
            end
          end
        end
      end

      update_colors
      @items_text.each(&.update(dt))
    end

    private def move_selection(dir : Int32)
      return if @items_text.empty?
      
      original_index = @selected_index
      loop do
        @selected_index = (@selected_index + dir) % @items_text.size
        break unless disabled?(@items[@selected_index][0])
        break if @selected_index == original_index # Avoid infinite loop if all disabled
      end
    end

    private def disabled?(id : Symbol) : Bool
      @items_disabled.includes?(id)
    end

    private def color_for(index : Int32) : Color
      id = @items[index][0]
      return @disabled_text_color if disabled?(id)
      
      if index == @selected_index
        return @selected_text_color.try(&.call(index)) || Color::Lime
      end

      if @mouse_hover && index == @hovered_index
        return @hover_text_color
      end

      @text_color.try(&.call(index)) || @default_text_color
    end

    private def update_colors
      @items_text.each_with_index do |item, index|
        item.color = color_for(index)
      end
    end

    def draw(draw : Draw)
      # Draw background box
      if box = @background_box
        draw_box_at(draw, box, 
          @x - (@menu_width * scale_x * origin[0]), 
          @y - (@menu_height * scale_y * origin[1]), 
          @menu_width * scale_x, 
          @menu_height * scale_y
        )
      end

      @items_text.each_with_index do |item, index|
        rect = @item_rects[index]
        id = @items[index][0]

        # Draw item boxes
        if disabled?(id) && (box = @disabled_box)
          draw_box_at(draw, box, rect[:x], rect[:y], rect[:w], rect[:h])
        elsif index == @selected_index && (box = @selected_box)
          draw_box_at(draw, box, rect[:x], rect[:y], rect[:w], rect[:h])
        elsif @mouse_hover && index == @hovered_index && (box = @hover_box)
          draw_box_at(draw, box, rect[:x], rect[:y], rect[:w], rect[:h])
        elsif box = @item_box
          draw_box_at(draw, box, rect[:x], rect[:y], rect[:w], rect[:h])
        end

        # Draw item text
        item.draw(draw)

        # Draw selected icon
        if index == @selected_index && (icon = @selected_icon)
          draw_icon(draw, icon, rect)
        end
      end
    end

    private def draw_box_at(draw : Draw, box : Box | SpriteBase, x : Num, y : Num, w : Num, h : Num)
      box.x = x
      box.y = y
      box.z_index = @z_index
      if box.is_a?(Box)
        box.width = w
        box.height = h
      end
      box.draw(draw)
    end

    private def draw_icon(draw : Draw, icon : SpriteBase, rect)
      icon_w = icon.draw_width
      icon_h = icon.draw_height
      
      icon_y = rect[:y] + (rect[:h] - icon_h) / 2.0_f32
      icon.z_index = @z_index

      if @selected_icon_placement == IconPlacement::Left || @selected_icon_placement == IconPlacement::Both
        icon.x = rect[:x] - icon_w - 5_f32
        icon.y = icon_y
        icon.draw(draw)
      end

      if @selected_icon_placement == IconPlacement::Right || @selected_icon_placement == IconPlacement::Both
        icon.x = rect[:x] + rect[:w] + 5_f32
        icon.y = icon_y
        icon.draw(draw)
      end
    end

    def scale_x : Num; scale[0]; end
    def scale_y : Num; scale[1]; end
  end
end
