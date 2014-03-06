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
#        target  => "edn_key"
#      }
#
#    }
#

  config :source, :validate => :string, :required => true
  # NOTE: if the `target` field already exists, it will be overwritten!
  config :target, :validate => :string

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
      # NOTE: EDN keywords automatically turn into Ruby Symbols because
      # of their same colon prefix notation such as ':key'. I do not know
      # if they must be converted to a string in something like:
      #   edn = Hash[ EDN.read(source).map{ |(k,v)| [k.to_s,v] } ]
      # But to do so it should be recursive (and maybe slow?).
      # To keep it simple is better to do what the 'edn' codec does and
      # execute a simple conversion.
      dest.merge!(EDN.read(source))

      filter_matched(event)

    rescue => e
      event.tag("_ednparsefailure")
      @logger.warn("Trouble parsing edn", :source => @source,
                   :raw => event[@source], :exception => e)
      return
    end

    @logger.debug("Event after edn filter", :event => event)

  end # def filter

end # class LogStash::Filters::Edn
