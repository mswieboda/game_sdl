module GSDL
  module Keys
    alias Keycode = LibSDL3::Keycode
    alias Keycodes = Array(Keycode)

    Unknown = LibSDL3::UNKNOWN
    Return = LibSDL3::RETURN
    Escape = LibSDL3::ESCAPE
    Backspace = LibSDL3::BACKSPACE
    Tab = LibSDL3::TAB
    Space = LibSDL3::SPACE
    A = LibSDL3::A
    B = LibSDL3::B
    C = LibSDL3::C
    D = LibSDL3::D
    E = LibSDL3::E
    F = LibSDL3::F
    G = LibSDL3::G
    H = LibSDL3::H
    I = LibSDL3::I
    J = LibSDL3::J
    K = LibSDL3::K
    L = LibSDL3::L
    M = LibSDL3::M
    N = LibSDL3::N
    O = LibSDL3::O
    P = LibSDL3::P
    Q = LibSDL3::Q
    R = LibSDL3::R
    S = LibSDL3::S
    T = LibSDL3::T
    U = LibSDL3::U
    V = LibSDL3::V
    W = LibSDL3::W
    X = LibSDL3::X
    Y = LibSDL3::Y
    Z = LibSDL3::Z
    Delete = LibSDL3::DELETE

    # Numbers
    Zero = LibSDL3::ZERO
    One = LibSDL3::ONE
    Two = LibSDL3::TWO
    Three = LibSDL3::THREE
    Four = LibSDL3::FOUR
    Five = LibSDL3::FIVE
    Six = LibSDL3::SIX
    Seven = LibSDL3::SEVEN
    Eight = LibSDL3::EIGHT
    Nine = LibSDL3::NINE

    # Punctuation
    Exclaim = LibSDL3::EXCLAIM
    Dblapostrophe = LibSDL3::DBLAPOSTROPHE
    Hash = LibSDL3::HASH
    Dollar = LibSDL3::DOLLAR
    Percent = LibSDL3::PERCENT
    Ampersand = LibSDL3::AMPERSAND
    Apostrophe = LibSDL3::APOSTROPHE
    Leftparen = LibSDL3::LEFTPAREN
    Rightparen = LibSDL3::RIGHTPAREN
    Asterisk = LibSDL3::ASTERISK
    Plus = LibSDL3::PLUS
    Comma = LibSDL3::COMMA
    Minus = LibSDL3::MINUS
    Period = LibSDL3::PERIOD
    Slash = LibSDL3::SLASH
    Colon = LibSDL3::COLON
    Semicolon = LibSDL3::SEMICOLON
    Less = LibSDL3::LESS
    Equals = LibSDL3::EQUALS
    Greater = LibSDL3::GREATER
    Question = LibSDL3::QUESTION
    At = LibSDL3::AT
    Leftbracket = LibSDL3::LEFTBRACKET
    Backslash = LibSDL3::BACKSLASH
    Rightbracket = LibSDL3::RIGHTBRACKET
    Caret = LibSDL3::CARET
    Underscore = LibSDL3::UNDERSCORE
    Grave = LibSDL3::GRAVE

    # Function keys
    F1 = LibSDL3::F1
    F2 = LibSDL3::F2
    F3 = LibSDL3::F3
    F4 = LibSDL3::F4
    F5 = LibSDL3::F5
    F6 = LibSDL3::F6
    F7 = LibSDL3::F7
    F8 = LibSDL3::F8
    F9 = LibSDL3::F9
    F10 = LibSDL3::F10
    F11 = LibSDL3::F11
    F12 = LibSDL3::F12

    # Other keys
    Capslock = LibSDL3::CAPSLOCK
    Printscreen = LibSDL3::PRINTSCREEN
    Scrolllock = LibSDL3::SCROLLLOCK
    Pause = LibSDL3::PAUSE
    Insert = LibSDL3::INSERT
    Home = LibSDL3::HOME
    Pageup = LibSDL3::PAGEUP
    End = LibSDL3::END
    Pagedown = LibSDL3::PAGEDOWN
    Right = LibSDL3::RIGHT
    Left = LibSDL3::LEFT
    Down = LibSDL3::DOWN
    Up = LibSDL3::UP

    # modifier keys
    # TODO: we still need all the others (see list in LibSDL3::Keymod)
    LShift = LibSDL3::LSHIFT
    RShift = LibSDL3::RSHIFT

    enum State
      JustPressed
      Pressed
      JustReleased
    end

    @@states = {} of Keycode => State
    @@multi_tap_tracker = GSDL::Input::MultiTapTracker(Keycode).new

    def self.multi_tap_tracker
      @@multi_tap_tracker
    end

    def self.update
      @@states.each do |key, state|
        case state
        when State::JustPressed
          @@states[key] = State::Pressed
        when State::JustReleased
          @@states.delete(key)
        else
          # No change for Pressed
        end
      end
      @@multi_tap_tracker.update(LibSDL3.get_ticks)
    end

    def self.handle_key_down(event : Event)
      key = event.key.key

      # only set to JustPressed if it's not already down
      unless pressed?(key)
        @@states[key] = State::JustPressed
        @@multi_tap_tracker.record_tap(key, LibSDL3.get_ticks)
      end
    end

    def self.handle_key_up(event : Event)
      @@states[event.key.key] = State::JustReleased
    end

    def self.pressed?(key : Keycode)
      @@states.has_key?(key) && (@@states[key] == State::Pressed || @@states[key] == State::JustPressed)
    end

    def self.pressed?(keys : Keycodes)
      keys.any? { |key| pressed?(key) }
    end

    def self.just_pressed?(key : Keycode)
      @@states.has_key?(key) && @@states[key] == State::JustPressed
    end

    def self.just_pressed?(keys : Keycodes)
      keys.any? { |key| just_pressed?(key) }
    end

    def self.just_released?(key : Keycode)
      @@states.has_key?(key) && @@states[key] == State::JustReleased
    end

    def self.just_released?(keys : Keycodes)
      keys.any? { |key| just_released?(key) }
    end

    def self.multi_tap?(key : Keycode, count : Int32) : Bool
      @@multi_tap_tracker.multi_tap?(key, count)
    end

    def self.double_tap?(key : Keycode) : Bool
      @@multi_tap_tracker.double_tap?(key)
    end

    def self.tap_count(key : Keycode) : Int32
      @@multi_tap_tracker.tap_count(key)
    end

    def self.clear
      @@states.clear
      @@multi_tap_tracker.clear
    end
  end
end
