# This is a patch for childprocess and this is due to ruby-cabin/fpm interaction.
# When we use the logger.pipe construct and the IO reach EOF we close the IO.
# The problem Childprocess will try to flush to it and hit an IOError making the software crash in JRuby 9k.
#
# In JRuby 1.7.25 we hit a thread death.
#
module ChildProcess
  module JRuby
    class Pump
      alias_method :old_pump, :pump

      def ignore_close_io
        old_pump
      rescue IOError
      end

      alias_method :pump, :ignore_close_io
    end
  end
end
