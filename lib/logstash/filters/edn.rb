# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

# This is a EDN parsing filter. It takes an existing field which contains EDN and
# expands it into an actual data structure within the Logstash event.
#
# Based on the code from 'json' filter.
#
class LogStash::Filters::Edn < LogStash::Filters::Base

  config_name "edn"
  milestone 1

#
# Usage example: when you have an 'edn' string as a remaining part of your log line:
#
#    input {
#       file {
#         type => "jetty"
#         path => "/var/log/jetty/*log"
#       }
#    }
#
#    filter {
#
#      grok {
#        type    => "jetty"
#        match   => [ "message", "%{TIMESTAMP_ISO8601}\s+%{LOGLEVEL:log_level}\s+%{GREEDYDATA:edn_msg}" ]
#        add_tag => [ "jetty", "grokked"]
#      }
#
#      edn {
#        source  => "edn_msg"
#      }
#
#    }
#

  config :source, :validate => :string, :required => true
  # NOTE: if the `target` field already exists, it will be overwritten!
  config :target, :validate => :string


  TIMESTAMP = "timestamp"

  public
  def register
    require 'edn'
  end # def register

  public
  def filter(event)

    return unless filter?(event)

    @logger.debug("Running json filter", :event => event)

    return unless event.include?(@source)

    source = event[@source]

    if @target.nil?
      # Default: to write to the root of the 'event'.
      dest = event.to_hash
    else
      if @target == @source
        # Overwrite source
        dest = event[@target] = {}
      else
        dest = event[@target] ||= {}
      end
    end

    begin

      # prevent EDN keys to be treated as Symbols
      edn = Hash[ EDN.read(source).map{ |(k,v)| [k.to_s,v] } ]

      # New entries into the destination
      dest.merge!(edn)

      # Same fix from the 'json' filter plugin....
      # If no @target, we target the root of the event object. This can allow
      # you to overwrite @timestamp. If so, let's parse it as a timestamp!
      if !@target && event[TIMESTAMP].is_a?(String)
        # This is a hack to help folks who are mucking with @timestamp during
        # their edn filter. You aren't supposed to do anything with
        # "@timestamp" outside of the date filter, but nobody listens... ;)
        event[TIMESTAMP] = Time.parse(event[TIMESTAMP]).utc
      end

      filter_matched(event)

    rescue => e
      event.tag("_ednparsefailure")
      @logger.warn("Trouble parsing edn", :source => @source, :raw => event[@source], :exception => e)
      return

    end

    @logger.debug("Event after edn filter", :event => event)

  end # def filter

end # class LogStash::Filters::Edn

