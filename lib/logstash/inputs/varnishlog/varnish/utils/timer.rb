module Varnish
  module Utils
    module Timer
      def timer_init
        @count = 0
        @time = 0
        @interval = 40000
      end

      def timer_count
        @time = Time.now if @count == 0
        @count += 1
        if (@count % @interval) == 0
          puts "Got #{@count} calls in #{(Time.now - @time).to_f}s"
          @time = Time.now
        end
      end
    end
  end
end
