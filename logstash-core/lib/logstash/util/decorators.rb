# encoding: utf-8
require "logstash/namespace"
require "logstash/util"

module LogStash::Util

  # Decorators provides common manipulation on the event data.
  module Decorators
    extend self
    
    @logger = Cabin::Channel.get(LogStash)

    # fields is a hash of field => value
    # where both `field` and `value` can use sprintf syntax.
    def add_fields(fields,event, pluginname)
      fields.each do |field, value|
        field = event.sprintf(field)
        value = Array(value)
        value.each do |v|
          v = event.sprintf(v)
          if event.include?(field)
            # note below that the array field needs to be updated then reassigned to the event.
            # this is important because a construct like event[field] << v will not work
            # in the current Java event implementation. see https://github.com/elastic/logstash/issues/4140
            a = Array(event[field])
            a << v
            event[field] = a
          else
            event[field] = v
          end
          @logger.debug? and @logger.debug("#{pluginname}: adding value to field", :field => field, :value => value)
        end
      end
    end

    # tags is an array of string. sprintf syntax can be used.
    def add_tags(tags, event, pluginname)
      tags.each do |tag|
        tag = event.sprintf(tag)
        @logger.debug? and @logger.debug("#{pluginname}: adding tag", :tag => tag)
        # note below that the tags array field needs to be updated then reassigned to the event.
        # this is important because a construct like event["tags"] << tag will not work
        # in the current Java event implementation. see https://github.com/elastic/logstash/issues/4140
        tags = event["tags"] || []
        tags << tag
        event["tags"] = tags
      end
    end

  end # module LogStash::Util::Decorators

end # module LogStash::Util
