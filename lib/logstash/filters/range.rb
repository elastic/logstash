require "logstash/filters/base"
require "logstash/namespace"

# This filter is used to check that certain fields are within expected size/length ranges.
# Supported types are numbers and strings.
# Numbers are checked to be within numeric value range.
# Strings are checked to be within string length range.
# More than one range can be specified for same fieldname, actions will be applied incrementally.
# Then field value is with in a specified range and action will be taken
# supported actions are drop event add tag or add field with specified value.
#
# Example usecases are for histogram like tagging of events
# or for finding anomaly values in fields or too big events that should be dropped.

class LogStash::Filters::Range < LogStash::Filters::Base
  config_name "range"
  plugin_status "experimental"

  # An array of field, min, max ,action tuples.
  # Example:
  #
  #     filter {
  #       %PLUGIN% {
  #         ranges => [ "@message", 0, 10, "tag:short",
  #                     "@message", 11, 100, "tag:medium",
  #                     "@message", 101, 1000, "tag:long",
  #                     "@message", 1001, 1e1000, "drop",
  #                     "duration", 0, 100, "field:latency:fast",
  #                     "duration", 101, 200, "field:latency:normal",
  #                     "duration", 201, 1000, "field:latency:slow",
  #                     "duration", 1001, 1e1000, "field:latency:outlier" 
  #                     "requests", 0, 10, "tag:to_few_%{@host_source}_requests" ]
  #       }
  #     }
  #
  # Supported actions are drop tag or field with specified value.
  # Added tag names and field names and field values can have %{dynamic} values.
  #
  # TODO(piavlo): The action syntax is ugly at the moment due to logstash grammar limitations - arrays grammar should support
  # TODO(piavlo): simple not nested hashses as values in addition to numaric and string values to prettify the syntax.
  config :ranges, :validate => :array, :default => []

  # Negate the range match logic, events should be outsize of the specificed range to match.
  config :negate, :validate => :boolean, :default => false

  public
  def register
    if @ranges.length % 4 != 0
      raise "#{self.class.name}: ranges array should consist of 4 field tuples (field,min,max,action)"
    end
  
    @range_tuples = {}

    while !@ranges.empty?
      fieldname, min, max, action = @ranges.shift(4)
      
      raise "#{self.class.name}: range field name value should be a string" if !fieldname.is_a?(String)
      raise "#{self.class.name}: range min value should be a number" if !min.is_a?(Integer) and !min.is_a?(Float)
      raise "#{self.class.name}: range min value should be a number" if !max.is_a?(Integer) and !max.is_a?(Float)
      raise "#{self.class.name}: range action value should be a string" if !action.is_a?(String)
      
      action = action.split(':')
      
      case action.first
      when "drop"
        raise "#{self.class.name}: drop action does not accept any parameters" unless action.length == 1
        action = { :name => :drop }
      when "tag"
        raise "#{self.class.name}: tag action accepts exactly one arg which is a tag name" unless action.length == 2
        action = { :name => :add_tag, :tag => action.last }
      when "field"
        raise "#{self.class.name}: field action accepts exactly 2 args which are a field name and field value" unless action.length == 3
        if action.last == action.last.to_i.to_s
          value = action.last.to_i
        elsif action.last == action.last.to_f.to_s
          value = action.last.to_f
        else
          value = action.last
        end
        action = { :name => :add_field, :field => action[1], :value => value }
      else
        raise "#{self.class.name}: unsupported action #{action}"
      end
      
      @range_tuples[fieldname] ||= []
      @range_tuples[fieldname] << { :min => min, :max => max, :action => action }
    end
  end # def register

 
  public
  def filter(event)
    return unless filter?(event)

    @range_tuples.each_key do |fieldname|
      if event.include?(fieldname)
        @range_tuples[fieldname].each do |range|
          matched = false
        
          field = event[fieldname]
          case field
          when Integer
            matched = field.between?(range[:min], range[:max])
          when Float
            matched = field.between?(range[:min], range[:max])
          when String
            matched = field.length.between?(range[:min], range[:max])
          else
            @logger.warn("#{self.class.name}: action field value has unsupported type")
          end

          matched = !matched if @negate
          next unless matched
        
          case range[:action][:name]
          when :drop
            @logger.debug? and @logger.debug("#{self.class.name}: dropping event due to range match", :event => event)
            event.cancel
            return
          when :add_tag
            @logger.debug? and @logger.debug("#{self.class.name}: adding tag due to range match",
                                             :event => event, :tag => range[:action][:tag] )
            event.tags << event.sprintf(range[:action][:tag])
          when :add_field
            @logger.debug? and @logger.debug("#{self.class.name}: adding field due to range match",
                                              :event => event, :field => range[:action][:field], :value => range[:action][:value])
            new_field = event.sprintf(range[:action][:field])
            if event[new_field]
              event[new_field] = [event[new_field]] if !event[new_field].is_a?(Array)
              event[new_field] << event.sprintf(range[:action][:value])
            else
              event[new_field] = range[:action][:value].is_a?(String) ? event.sprintf(range[:action][:value]) : range[:action][:value]
            end
          end
        end
      end
    end
    
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Range
