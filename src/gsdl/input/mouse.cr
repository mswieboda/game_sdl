module GSDL
  module Mouse
    # TODO: make enum
    ButtonLeft = 1_u8
    ButtonMiddle = 2_u8
    ButtonRight = 3_u8

    enum State
      JustPressed
      Pressed
      JustReleased
    end

    @@states = {} of UInt8 => State
    @@drag_start_x = {} of UInt8 => Int32
    @@drag_start_y = {} of UInt8 => Int32
    @@x = 0
    @@y = 0
    @@prev_x = 0
    @@prev_y = 0
    @@moved = false

    def self.x
      @@x
    end

    def self.y
      @@y
    end

    def self.dx
      @@x - @@prev_x
    end

    def self.dy
      @@y - @@prev_y
    end

    def self.position
      {@@x, @@y}
    end

    def self.moved?
      @@moved
    end

    def self.dragging?(button : UInt8 = ButtonLeft)
      pressed?(button)
    end

    def self.drag_offset_x(button : UInt8 = ButtonLeft)
      return 0 if !pressed?(button) || !@@drag_start_x.has_key?(button)
      @@x - @@drag_start_x[button]
    end

    def self.drag_offset_y(button : UInt8 = ButtonLeft)
      return 0 if !pressed?(button) || !@@drag_start_y.has_key?(button)
      @@y - @@drag_start_y[button]
    end

    def self.in?(x : Num, y : Num, width : Num, height : Num)
      in_x = self.x >= x && self.x <= x + width
      in_y = self.y >= y && self.y <= y + height

      in_x && in_y
    end

    def self.clicked_in?(x : Num, y : Num, width : Num, height : Num, button : UInt8 = ButtonLeft)
      in?(x, y, width, height) && just_pressed?(button)
    end

    def self.update
      @@states.each do |button, state|
        case state
        when State::JustPressed
          @@states[button] = State::Pressed
        when State::JustReleased
          @@states.delete(button)
        else
          # No change for Pressed
        end
      end

      @@moved = (@@x != @@prev_x || @@y != @@prev_y)
      @@prev_x = @@x
      @@prev_y = @@y
    end

    def self.handle_mouse_motion(event : Event)
      @@x = event.motion.x.to_i
      @@y = event.motion.y.to_i
    end

    def self.handle_mouse_button_down(event : Event)
      button = event.button.button
      unless pressed?(button)
        @@states[button] = State::JustPressed
        @@drag_start_x[button] = event.button.x.to_i
        @@drag_start_y[button] = event.button.y.to_i
      end
    end

    def self.handle_mouse_button_up(event : Event)
      button = event.button.button
      @@states[button] = State::JustReleased
      @@drag_start_x.delete(button)
      @@drag_start_y.delete(button)
    end

    def self.pressed?(button : UInt8)
      @@states.has_key?(button) && (@@states[button] == State::Pressed || @@states[button] == State::JustPressed)
    end

    def self.pressed?(buttons : Array(UInt8))
      buttons.any? { |button| pressed?(button) }
    end

    def self.just_pressed?(button : UInt8)
      @@states.has_key?(button) && @@states[button] == State::JustPressed
    end

    def self.just_pressed?(buttons : Array(UInt8))
      buttons.any? { |button| just_pressed?(button) }
    end

    def self.just_released?(button : UInt8)
      @@states.has_key?(button) && @@states[button] == State::JustReleased
    end

    def self.just_released?(buttons : Array(UInt8))
      buttons.any? { |button| just_released?(button) }
    end

    def self.show
      SDL3::Mouse.show
    end

    def self.hide
      SDL3::Mouse.hide
    end

    def self.visible?
      SDL3::Mouse.visible?
    end

    def self.visible=(value : Bool)
      value ? show : hide
    end

    def self.cursor=(cursor : Cursor)
      SDL3::Mouse.set_cursor(cursor.to_sdl)
    end

    def self.set_cursor(cursor : Cursor)
      self.cursor = cursor
    end
  end
end

