require "logstash/filters/base"
require "logstash/namespace"

require "csv"

# CSV filter. Takes an event field containing CSV data, parses it,
# and stores it as individual fields (can optionally specify the names).
class LogStash::Filters::CSV < LogStash::Filters::Base
  config_name "csv"
  plugin_status "beta"

  # Config for csv is:
  #   "source => dest".
  # The CSV data in the value of the source field will be expanded into a
  # datastructure in the "dest" field.  Note: if the "dest" field
  # already exists, it will be overridden.
  config /[A-Za-z0-9_-]+/, :validate => :string, :deprecated => true

  # Define a list of field names (in the order they appear in the CSV,
  # as if it were a header line). If this is not specified or there
  # are not enough fields specified, the default field name is "fieldN"
  # (where N is the field number, starting from 1).
  # Optional.
  config :fields, :validate => :array, :deprecated => true

  # The CSV data in the value of the source field will be expanded into a
  # datastructure.
  # This deprecates the regexp '[A-Za-z0-9_-]' variable.
  config :source, :validate => :string

  # Define a list of column names (in the order they appear in the CSV,
  # as if it were a header line). If this is not specified or there
  # are not enough columns specified, the default column name is "columnX"
  # (where X is the field number, starting from 1).
  # This deprecates the 'fields' variable.
  # Optional.
  config :columns, :validate => :array, :default => []

  # Define the column separator value. If this is not specified the default
  # is a comma ','
  # Optional.
  config :separator, :validate => :string, :default => ","

  # Define target for placing the data
  # Defaults to @fields
  # Optional
  config :target, :validate => :string, :default => "@fields"

  public
  def register

    #TODO(electrical): At some point 'fields' and the regexp parts need to be removed.
    if @fields
      if @columns
        @logger.error("'fields' and 'columns' are the same setting, but 'fields' is deprecated. Please use only 'columns'")
      end
      @columns = @fields
    end

    @csv = {}
    #TODO(electrical): At some point this can be removed
    @config.each do |field, dest|
      next if (RESERVED + ["fields", "separator", "source", "columns", "target"]).member?(field)
      @logger.warn("You used a deprecated setting '#{field} => #{dest}'. You should use 'source => "%{field}"' and 'target => %{dest}'")
      @csv[field] = dest
    end

    #TODO(electrical): Will we make @source required or not?
    if @source
      #Add the source field to the list.
      @csv[@source] = @target
    end

    # Default to parsing @message and dumping into @target
    if @csv.empty?
      @csv["@message"] = @target
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running csv filter", :event => event)

    matches = 0
    #TODO(electrical): When old stuff can be removed. this block will need to be changed also
    @csv.each do |key, dest|
      if event[key]
        if event[key].is_a?(String)
          event[key] = [event[key]]
        end

        if event[key].length > 1
          @logger.warn("csv filter only works on fields of length 1",
                       :key => key, :value => event[key],
                       :event => event)
          next
        end

        raw = event[key].first
        begin
          values = CSV.parse_line(raw, {:col_sep => @separator})
          data = {}
          values.each_index do |i|
            field_name = @columns[i] || "column#{i+1}"
            data[field_name] = values[i]
          end

          event[dest] = data

          filter_matched(event)
        rescue => e
          event.tags << "_csvparsefailure"
          @logger.warn("Trouble parsing csv", :key => key, :raw => raw,
                        :exception => e, :backtrace => e.backtrace)
          next
        end # begin
      end # @csv.each
    end # def filter

    @logger.debug("Event after csv filter", :event => event)
  end # def filter
end # class LogStash::Filters::Csv

