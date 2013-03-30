require "logstash/filters/base"
require "logstash/namespace"

# The alter filter allows you to do general alterations to fields 
# that are not included in the normal mutate filter. 
#
#
# NOTE: The functionality provided by this plugin is likely to
# be merged into the 'mutate' filter in future versions.
class LogStash::Filters::Alter < LogStash::Filters::Base
  config_name "alter"
  plugin_status "experimental"
  
  # Change the content of the field to the specified value
  # if the actual content is equal to the expected one.
  #
  # Example:
  #
  #     filter {
  #       alter {
  #         condrewrite => [ 
  #              "field_name", "expected_value", "new_value" 
  #              "field_name2", "expected_value2, "new_value2"
  #              ....
  #            ]
  #       }
  #     }
  config :condrewrite, :validate => :array
  
  # Change the content of the field to the specified value
  # if the content of another field is equal to the expected one.
  #
  # Example:
  #
  #     filter {
  #       alter {
  #         condrewriteother => [ 
  #              "field_name", "expected_value", "field_name_to_change", "value",
  #              "field_name2", "expected_value2, "field_name_to_change2", "value2",
  #              ....
  #         ]
  #       }
  #     }
  config :condrewriteother, :validate => :array
  
  # Sets the value of field_name to the first nonnull expression among its arguments.
  #
  # Example:
  #
  #     filter {
  #       alter {
  #         coalesce => [
  #              "field_name", "value1", "value2", "value3", ...
  #         ]
  #       }
  #     }
  config :coalesce, :validate => :array
  
  public
  def register 
    @condrewrite_parsed = []
    @condrewrite.nil? or @condrewrite.each_slice(3) do |field, expected, replacement|
      if [field, expected, replacement].any? {|n| n.nil?}
        @logger.error("Invalid condrewrte configuration. condrewrite has to define 3 elements per config entry", :field => field, :expected => expected, :replacement => replacement)
        raise "Bad configuration, aborting."
      end
      @condrewrite_parsed << {
        :field        => field,
        :expected       => expected,
        :replacement  => replacement
      }
    end # condrewrite
    
    @condrewriteother_parsed = []
    @condrewriteother.nil? or @condrewriteother.each_slice(4) do |field, expected, replacement_field, replacement_value|
      if [field, expected, replacement_field, replacement_value].any? {|n| n.nil?}
        @logger.error("Invalid condrewrteother configuration. condrewriteother has to define 4 elements per config entry", :field => field, :expected => expected, :replacement_field => replacement_field, :replacement_value => replacement_value)
        raise "Bad configuration, aborting."
      end
      @condrewriteother_parsed << {
        :field        => field,
        :expected       => expected,
        :replacement_field  => replacement_field,
        :replacement_value => replacement_value
      }
    end # condrewriteother
    
    @coalesce_parsed = []
    @coalesce.nil? or if not @coalesce.is_a?(Array) or @coalesce.length < 2
      @logger.error("Invalid coalesce configuration. coalesce has to define one Array of at least 2 elements")
      raise "Bad configuration, aborting."
    else
      @coalesce_parsed << {
        :field  => @coalesce.slice!(0),
        :subst_array => @coalesce
      }
    end
    
       
  end # def register
  
  public
  def filter(event)
    return unless filter?(event)

    condrewrite(event) if @condrewrite
    condrewriteother(event) if @condrewriteother
    coalesce(event) if @coalesce

    filter_matched(event)
  end # def filter
  
  private
  def condrewrite(event)
    @condrewrite_parsed.each do |config|
      field = config[:field]
      expected = config[:expected]
      replacement = config[:replacement]

      if event[field].is_a?(Array)
        event[field] = event[field].map do |v|
          if v == event.sprintf(expected)
            v = event.sprintf(replacement)
          else
            v
          end
        end
      else
        if event[field] == event.sprintf(expected)
          event[field] = event.sprintf(replacement)
        end
      end
    end # @condrewrite_parsed.each
  end # def condrewrite
  
  private
  def condrewriteother(event)
    @condrewriteother_parsed.each do |config|
      field = config[:field]
      expected = config[:expected]
      replacement_field = config[:replacement_field]
      replacement_value = config[:replacement_value]

      if event[field].is_a?(Array)
        event[field].each do |v|
          if v == event.sprintf(expected)
            event[replacement_field] = event.sprintf(replacement_value)
          end
        end
      else
        if event[field] == event.sprintf(expected)
          event[replacement_field] = event.sprintf(replacement_value)
        end
      end
    end # @condrewriteother_parsed.each
  end # def condrewriteother
  
  private
  def coalesce(event)
    @coalesce_parsed.each do |config|
      field = config[:field]
      subst_array = config[:subst_array]
      
      substitution_parsed = subst_array.map { |x| event.sprintf(x) }
      not_nul_index = substitution_parsed.find_index { |x| not x.nil? and not x.eql?("nil") and not (not x.index("%").nil? && x.match(/%\{[^}]\}/).nil?) }
      if not not_nul_index.nil?
        event[field] = substitution_parsed[not_nul_index]
      end
    end # @coalesce_parsed.each
  end # def coalesce
  
end # class LogStash::Filters::Alter
