module GSDL
  abstract class EventHandler
    # Return true if event was consumed/handled
    abstract def handle(event : Event, window : SDL3::Window) : Bool
  end
end
