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
    @@wheel_x = 0_f32
    @@wheel_y = 0_f32
    @@moved = false
    @@multi_tap_tracker = GSDL::Input::MultiTapTracker(UInt8).new

    def self.multi_tap_tracker
      @@multi_tap_tracker
    end

    def self.x
      window = GSDL::Game.instance.window
      pts_w, _ = window.size
      px_w, _ = window.pixel_size
      scale = pts_w.to_f32 / px_w.to_f32
      (@@x * scale).to_i
    end

    def self.y
      window = GSDL::Game.instance.window
      _, pts_h = window.size
      _, px_h = window.pixel_size
      scale = pts_h.to_f32 / px_h.to_f32
      (@@y * scale).to_i
    end

    def self.dx
      window = GSDL::Game.instance.window
      pts_w, _ = window.size
      px_w, _ = window.pixel_size
      scale = pts_w.to_f32 / px_w.to_f32
      ((@@x - @@prev_x) * scale).to_i
    end

    def self.dy
      window = GSDL::Game.instance.window
      _, pts_h = window.size
      _, px_h = window.pixel_size
      scale = pts_h.to_f32 / px_h.to_f32
      ((@@y - @@prev_y) * scale).to_i
    end

    def self.wheel_x
      @@wheel_x
    end

    def self.wheel_y
      @@wheel_y
    end

    def self.position
      {self.x, self.y}
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

      @@multi_tap_tracker.update(LibSDL3.get_ticks)

      @@wheel_x = 0_f32
      @@wheel_y = 0_f32

      @@moved = (@@x != @@prev_x || @@y != @@prev_y)
      @@prev_x = @@x
      @@prev_y = @@y
    end

    def self.handle_mouse_motion(event : Event)
      mx, my = 0_f32, 0_f32

      LibSDL3.render_coordinates_from_window(
        GSDL::Game.draw.to_sdl.to_unsafe,
        event.motion.x,
        event.motion.y,
        pointerof(mx),
        pointerof(my)
      )

      @@x = mx.to_i
      @@y = my.to_i
    end

    def self.handle_mouse_button_down(event : Event)
      button = event.button.button
      mx, my = 0_f32, 0_f32

      LibSDL3.render_coordinates_from_window(
        GSDL::Game.draw.to_sdl.to_unsafe,
        event.button.x,
        event.button.y,
        pointerof(mx),
        pointerof(my)
      )

      unless pressed?(button)
        @@states[button] = State::JustPressed
        @@multi_tap_tracker.record_tap_with_count(button, event.button.clicks.to_i, LibSDL3.get_ticks)
        @@drag_start_x[button] = mx.to_i
        @@drag_start_y[button] = my.to_i
      end
    end

    def self.handle_mouse_button_up(event : Event)
      button = event.button.button
      @@states[button] = State::JustReleased
      @@drag_start_x.delete(button)
      @@drag_start_y.delete(button)
    end

    def self.handle_mouse_wheel(event : Event)
      @@wheel_x = event.wheel.x
      @@wheel_y = event.wheel.y
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

    def self.multi_tap?(button : UInt8, count : Int32) : Bool
      @@multi_tap_tracker.multi_tap?(button, count)
    end

    def self.double_tap?(button : UInt8) : Bool
      @@multi_tap_tracker.double_tap?(button)
    end

    def self.tap_count(button : UInt8) : Int32
      @@multi_tap_tracker.tap_count(button)
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

    def self.clear
      @@states.clear
      @@drag_start_x.clear
      @@drag_start_y.clear
      @@multi_tap_tracker.clear
      @@x = 0
      @@y = 0
      @@prev_x = 0
      @@prev_y = 0
      @@wheel_x = 0_f32
      @@wheel_y = 0_f32
      @@moved = false
    end
  end
end
