require "logstash/filters/base"

class LogStash::Filters::Test < LogStash::Filters::Base
    config_name "test"

    config :foo, :validate => :string

    def register
        # nothing
    end

    def multi_filter(events)
        events.each do |event|
            event.set("test", 1);
            filter_matched(event)
        end
    end
end

