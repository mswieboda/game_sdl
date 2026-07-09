struct FingerState
  property id : Int64
  property x : Float64
  property y : Float64
  property down : Bool
  property just_pressed : Bool

  def initialize(@id, @x, @y, @down, @just_pressed)
  end
end

module GSDL
  module Touch
    @@fingers = {} of Int64 => FingerState

    def self.fingers
      @@fingers
    end

    def self.active_fingers : Array(FingerState)
      @@fingers.values
    end

    def self.pressed?(finger_id : Int64) : Bool
      if finger = @@fingers[finger_id]?
        finger.down
      else
        false
      end
    end

    def self.just_pressed?(finger_id : Int64) : Bool
      if finger = @@fingers[finger_id]?
        finger.just_pressed
      else
        false
      end
    end

    def self.project(x : Float64, y : Float64) : Tuple(Float64, Float64)
      window = GSDL::Game.instance.window
      pts_w, pts_h = window.size
      wx = x * pts_w
      wy = y * pts_h

      mx, my = 0_f32, 0_f32
      LibSDL3.render_coordinates_from_window(
        GSDL::Game.draw.to_sdl.to_unsafe,
        wx,
        wy,
        pointerof(mx),
        pointerof(my)
      )
      {mx.to_f64, my.to_f64}
    end

    def self.position(finger_id : Int64) : Tuple(Float64, Float64)
      if finger = @@fingers[finger_id]?
        project(finger.x, finger.y)
      else
        {0.0, 0.0}
      end
    end

    def self.x(finger_id : Int64) : Float64
      position(finger_id)[0]
    end

    def self.y(finger_id : Int64) : Float64
      position(finger_id)[1]
    end

    def self.update
      # Reset just_pressed states at the start of every frame
      @@fingers.each do |id, finger|
        if finger.just_pressed
          @@fingers[id] = FingerState.new(
            id: finger.id,
            x: finger.x,
            y: finger.y,
            down: finger.down,
            just_pressed: false
          )
        end
      end
    end

    def self.handle_finger_down(event : Event)
      finger_id = event.tfinger.finger_id
      x = event.tfinger.x.to_f64
      y = event.tfinger.y.to_f64
      @@fingers[finger_id] = FingerState.new(
        id: finger_id,
        x: x,
        y: y,
        down: true,
        just_pressed: true
      )
    end

    def self.handle_finger_motion(event : Event)
      finger_id = event.tfinger.finger_id
      x = event.tfinger.x.to_f64
      y = event.tfinger.y.to_f64
      just_pressed = if prev = @@fingers[finger_id]?
                       prev.just_pressed
                     else
                       false
                     end
      @@fingers[finger_id] = FingerState.new(
        id: finger_id,
        x: x,
        y: y,
        down: true,
        just_pressed: just_pressed
      )
    end

    def self.handle_finger_up(event : Event)
      finger_id = event.tfinger.finger_id
      @@fingers.delete(finger_id)
    end

    def self.clear
      @@fingers.clear
    end
  end
end
