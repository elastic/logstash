java_import 'com.logstash.pipeline.ComponentProcessor'
java_import 'com.logstash.pipeline.BooleanEventsResult'

module LogStash; class Pipeline
  class RubyComponentProcessor
    include com.logstash.pipeline.ComponentProcessor

    def initialize(pipeline,&block)
      @lookup = {}
      @execution_lookup = {}
      @pipeline = pipeline
      @on_setup = block
      @compiled_conditions = {}
    end

    def setup(component)
      type, name = component.getComponentName.split("-", 2)
      options = component.getOptionsStr ? LogStash::Json.load(component.getOptionsStr) : {}
      return if ["queue","predicate"].include?(type) # TODO: One day this will do something...
      plugin = @pipeline.plugin(type, name, options)
      @on_setup.call(component, plugin) if @on_setup
      @lookup[component] = plugin
      @execution_lookup[component] = if plugin.is_a? LogStash::FilterDelegator
                                       proc do |events|
                                         out = plugin.multi_filter(events)
                                         @pipeline.events_filtered.increment(out.length)
                                         out
                                       end
                                       plugin.method(:multi_filter)
                                     elsif plugin.is_a? LogStash::OutputDelegator
                                       proc do |events|
                                         out = plugin.multi_receive(events)
                                         @pipeline.events_consumed.increment(out.length)
                                         out
                                       end
                                     end
    end

    def process(component, events)
      rubyified_events = rubyify_events(events.compact)
      res = @execution_lookup[component].call(rubyified_events)

      javaify_events(res)
    end

    def rubyify_events(java_events)
      java_events.map {|e| Event.from_java(e)}
    end

    def javaify_events(ruby_events)
      ruby_events.map {|e| e.to_java}
    end

    def flush(component, shutdown)
      component = @lookup[component]
      if component.respond_to?(:flush)
        component.flush()
      end
    end

    def process_condition(condition, events)
      ber = com.logstash.pipeline.BooleanEventsResult.new
      compiled_condition(condition).call(events,ber.getTrueEvents, ber.getFalseEvents)
      ber
    end

    def compiled_condition(condition)
      @compiled_conditions[condition] ||= eval("proc {|events,t,f| events.each {|event_j| event = Event.from_java(event_j); (#{condition.source}) ? t.add(event_j) : f.add(event_j) } }")
    end
  end
end end