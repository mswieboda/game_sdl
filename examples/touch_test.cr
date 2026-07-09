require "../src/game_sdl"

class TestGame < GSDL::Game
  def initialize
    super(title: "Touch Automated Test")
  end

  def init
    run_tests
  rescue e
    puts "Test Failure: #{e.message}"
    puts e.backtrace.join("\n")
    STDOUT.flush
    exit 1
  end

  def run_tests
    puts "Running Touch Tests..."

    # 1. Verify initially no active fingers
    if !GSDL::Touch.active_fingers.empty?
      raise "Expected no active fingers initially"
    end

    # 2. Push SDL_EVENT_FINGER_DOWN
    event = uninitialized LibSDL3::Event
    event.type = LibSDL3::SDL_EVENT_FINGER_DOWN
    event.tfinger.finger_id = 42_i64
    event.tfinger.x = 0.5_f32
    event.tfinger.y = 0.5_f32
    event.tfinger.pressure = 1.0_f32
    SDL3.push_event(pointerof(event))

    # Process events
    GSDL::Events.handle_events(window)

    # Verify GSDL::Touch state
    if GSDL::Touch.active_fingers.size != 1
      raise "Expected 1 active finger, got #{GSDL::Touch.active_fingers.size}"
    end
    if !GSDL::Touch.pressed?(42_i64)
      raise "Expected finger 42 to be pressed"
    end
    if !GSDL::Touch.just_pressed?(42_i64)
      raise "Expected finger 42 to be just pressed"
    end

    # Check coordinate translation
    pos = GSDL::Touch.position(42_i64)
    puts "Touch Position at (0.5, 0.5): #{pos}"

    # 3. Process next frame (update loop resets just_pressed)
    GSDL::InputEvents.update
    if GSDL::Touch.just_pressed?(42_i64)
      raise "Expected finger 42 not to be just_pressed on next frame"
    end
    if !GSDL::Touch.pressed?(42_i64)
      raise "Expected finger 42 to still be pressed"
    end

    # 4. Push SDL_EVENT_FINGER_MOTION
    event2 = uninitialized LibSDL3::Event
    event2.type = LibSDL3::SDL_EVENT_FINGER_MOTION
    event2.tfinger.finger_id = 42_i64
    event2.tfinger.x = 0.75_f32
    event2.tfinger.y = 0.75_f32
    event2.tfinger.pressure = 1.0_f32
    SDL3.push_event(pointerof(event2))

    # Process events
    GSDL::Events.handle_events(window)
    pos2 = GSDL::Touch.position(42_i64)
    puts "Touch Position after motion to (0.75, 0.75): #{pos2}"

    # 5. Push SDL_EVENT_FINGER_UP
    event3 = uninitialized LibSDL3::Event
    event3.type = LibSDL3::SDL_EVENT_FINGER_UP
    event3.tfinger.finger_id = 42_i64
    SDL3.push_event(pointerof(event3))

    # Process events
    GSDL::Events.handle_events(window)
    if GSDL::Touch.pressed?(42_i64)
      raise "Expected finger 42 to be released"
    end
    if !GSDL::Touch.active_fingers.empty?
      raise "Expected no active fingers after release"
    end

    puts "All Touch Tests Passed!"
    STDOUT.flush
    exit 0
  end
end

TestGame.new.run
