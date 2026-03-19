module GSDL
  module Input
    class MultiTapTracker(T)
      property time_window : UInt64 = 250_u64

      @tap_counts = {} of T => Int32
      @last_tap_times = {} of T => UInt64

      def update(current_time : UInt64)
        # Decay taps that have exceeded the time window
        keys_to_delete = [] of T
        @last_tap_times.each do |key, time|
          if current_time > time && (current_time - time) > @time_window
            keys_to_delete << key
          end
        end

        keys_to_delete.each do |key|
          @tap_counts.delete(key)
          @last_tap_times.delete(key)
        end
      end

      def record_tap(key : T, current_time : UInt64)
        if @last_tap_times.has_key?(key) && current_time >= @last_tap_times[key] && (current_time - @last_tap_times[key]) <= @time_window
          @tap_counts[key] = @tap_counts.fetch(key, 0) + 1
        else
          @tap_counts[key] = 1
        end
        @last_tap_times[key] = current_time
      end

      def tap_count(key : T) : Int32
        @tap_counts.fetch(key, 0)
      end

      def multi_tap?(key : T, count : Int32) : Bool
        tap_count(key) >= count
      end

      def double_tap?(key : T) : Bool
        multi_tap?(key, 2)
      end
    end
  end
end
