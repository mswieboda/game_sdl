module GSDL
  class Timer
    property duration : Time::Span

    @start_time : Time | Nil
    @paused_duration : Time::Span | Nil

    def initialize(duration = Time::Span.new, initialize_as_done = false)
      @duration = duration
      @start_time = nil
      @paused_duration = nil

      if initialize_as_done
        @start_time = duration.ago
      end
    end

    def start
      @paused_duration = nil
      @start_time = Time.local
    end

    def stop
      @paused_duration = nil
      @start_time = nil
    end

    def restart
      start
    end

    def pause
      @paused_duration = elapsed
    end

    def paused?
      @paused_duration != nil
    end

    def started?
      @start_time != nil
    end

    def elapsed : Time::Span
      if paused_duration = @paused_duration
        return paused_duration
      end

      return Time::Span.new unless start_time = @start_time

      Time.local - start_time
    end

    def done?
      return false unless started?

      elapsed >= @duration
    end

    def running?
      return false unless started?

      elapsed < @duration
    end

    def percent : Float32
      if elapsed >= duration
        1.0_f32
      else
        [percent_infinite, 1.0_f32].min
      end
    end

    @[AlwaysInline]
    def percent_infinite : Float32
      (elapsed / @duration).to_f32
    end
  end
end
