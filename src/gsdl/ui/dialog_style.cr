module GSDL
  struct DialogStyle
    # Main Box Configuration
    getter x : Float32
    getter y : Float32
    getter width : Int32
    getter height : Int32?
    getter origin : Tuple(Float32, Float32)
    getter color : Color
    getter bg_color : Color
    getter border_radius : Float32

    # Choices Configuration
    getter choices_x : Float32
    getter choices_y : Float32
    getter choices_origin : Tuple(Float32, Float32)
    getter choice_width : Int32
    getter choice_height : Int32?
    getter choice_spacing : Float32
    getter choice_color : Color
    getter choice_bg_color : Color
    getter choice_border_radius : Float32
    getter selected_prefix : String
    getter unselected_prefix : String

    def initialize(
      @x : Float32 = 400_f32,
      @y : Float32 = 400_f32,
      @width : Int32 = 700,
      @height : Int32? = nil,
      @origin : Tuple(Float32, Float32) = {0.5_f32, 0.0_f32},
      @color : Color = Color::Black,
      @bg_color : Color = Color::White,
      @border_radius : Float32 = 8.0_f32,

      @choices_x : Float32 = 400_f32,
      @choices_y : Float32 = 510_f32,
      @choices_origin : Tuple(Float32, Float32) = {0.5_f32, 0.0_f32},
      @choice_width : Int32 = 650,
      @choice_height : Int32? = nil,
      @choice_spacing : Float32 = 40.0_f32,
      @choice_color : Color = Color::Black,
      @choice_bg_color : Color = Color::White,
      @choice_border_radius : Float32 = 4.0_f32,
      @selected_prefix : String = "> ",
      @unselected_prefix : String = "  ",
    )
    end

    def self.classic_rpg
      new(
        x: 400_f32,
        y: 320_f32,
        width: 700,
        height: 120,
        origin: {0.5_f32, 0.0_f32},
        choices_x: 400_f32,
        choices_y: 450_f32,
        choices_origin: {0.5_f32, 0.0_f32},
        choice_width: 650,
        choice_height: nil,      # Auto-size to prevent text cutoff
        choice_spacing: 10.0_f32 # Margin between boxes
      )
    end

    def self.side_panel
      new(
        x: 400_f32,
        y: 40_f32,
        width: 600,
        height: 130,
        origin: {0.5_f32, 0.0_f32},
        choices_x: 760_f32,
        choices_y: 200_f32,
        choices_origin: {1.0_f32, 0.0_f32},
        choice_width: 320,
        choice_height: nil,     # Auto-size to prevent text cutoff
        choice_spacing: 8.0_f32 # Margin between boxes
      )
    end
  end
end
