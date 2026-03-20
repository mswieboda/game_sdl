module GSDL
  class Performance
    @samples = {} of String => Array(Float64)
    @current_frame_accum = {} of String => Float64
    @sample_limit : Int32

    # A rolling average of samples for each named measurement
    getter metrics = {} of String => Float64

    def self.instance
      @@instance ||= new
    end

    def initialize(@sample_limit = 120)
      # Pre-initialize common metrics in GSDL::Data
      ["update", "draw", "collision", "query"].each do |name|
        GSDL::Data.set("perf_#{name}", 0.0)
      end
    end

    # Measure the execution time of a block and accumulate it for the current frame.
    def measure(name : String, &block)
      if !Game.instance.performance_monitoring_enabled
        return yield
      end

      start = Time.instant
      begin
        yield
      ensure
        elapsed = (Time.instant - start).total_milliseconds
        @current_frame_accum[name] ||= 0.0
        @current_frame_accum[name] += elapsed
      end
    end

    # Complete the measurement cycle for the current frame.
    # Averages accumulated times into rolling samples and updates GSDL::Data.
    def end_frame
      return if !Game.instance.performance_monitoring_enabled

      @current_frame_accum.each do |name, elapsed|
        add_sample(name, elapsed)
      end
      @current_frame_accum.clear
    end

    # Increment a counter for the current frame.
    def increment(name : String, amount = 1)
      return if !Game.instance.performance_monitoring_enabled
      @current_frame_accum[name] ||= 0.0
      @current_frame_accum[name] += amount
    end

    private def add_sample(name : String, elapsed : Float64)
      @samples[name] ||= [] of Float64
      @samples[name] << elapsed
      if @samples[name].size > @sample_limit
        @samples[name].shift
      end

      avg = @samples[name].sum / @samples[name].size
      @metrics[name] = avg

      # Update GSDL::Data for UI binding
      GSDL::Data.set("perf_#{name}", avg)
    end
  end
end
