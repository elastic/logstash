# encoding: utf-8
require 'logstash/errors'

module LogStash module BootstrapCheck
    class PersistedQueueConfig
      def self.check(settings)
        return unless settings.get('queue.type') == 'persisted'
        if settings.get('queue.page_capacity') > settings.get('queue.max_bytes')
          raise LogStash::BootstrapCheckError,
                'Invalid configuration, `queue.page_capacity` must be smaller or equal to `queue.max_bytes`'
        end
      end
    end
end end
