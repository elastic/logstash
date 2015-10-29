# encoding: utf-8
require "logstash/namespace"
require "concurrent/concern/logging"
require "concurrent/concern/deprecation"
require "concurrent/version"
require "cabin"

# Concurrent-ruby is throwing warning when the code is run under jdk7, and they
# will provide best effort support, logstash has to support JDK7 for a few months.
#
# By default all deprecation warnings of the concurrent ruby
# library use the `WARN` level which is show everytime we boot logstash,
# This monkeypatch change the log level of the deprecation warning to be `debug`
# instead. This monkey patch might be a bit over kill but there is no
# easy way to override the java version check.
#
# ref: https://github.com/ruby-concurrency/concurrent-ruby/blob/v0.9.1/lib/concurrent/configuration.rb#L284-L295
#
# This patch is only valid for 0.9.1
if Concurrent::VERSION == "0.9.1"
  module Concurrent
    module Concern
      module Deprecation
        include Concern::Logging

        def deprecated(message, strip = 2)
          caller_line = caller(strip).first if strip > 0
          klass       = if Module === self
                          self
                        else
                          self.class
                        end
          message     = if strip > 0
                          format("[DEPRECATED] %s\ncalled on: %s", message, caller_line)
                        else
                          format('[DEPRECATED] %s', message)
                        end

          # lets use our logger
          logger = Cabin::Channel.get(LogStash)
          logger.debug(message, :class => klass.to_s)
        end

        extend self
      end
    end
  end
else
  # This is added a guard to check if we need to update this code or not.
  # Keep in mind, the latest releases of concurrent-ruby brokes a few stuff.
  #
  # Even the latest master version changed how they handle deprecation.
  raise "Logstash expects concurrent-ruby version 0.9.1 and version #{Concurrent::VERSION} is installed, please verify this patch: #{__FILE__}"
end
