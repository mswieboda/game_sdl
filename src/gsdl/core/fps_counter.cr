module GSDL
  class FPSCounter
    getter fps : Int32 = 0
    @frame_times = [] of Float32
    @sample_size : Int32

    def initialize(@sample_size = 60)
    end

    def update(dt : Float32)
      @frame_times << dt
      if @frame_times.size > @sample_size
        @frame_times.shift
      end

      if @frame_times.size > 0
        avg_dt = @frame_times.sum / @frame_times.size
        @fps = avg_dt > 0 ? (1.0 / avg_dt).to_i : 0
      end
    end
  end
end
