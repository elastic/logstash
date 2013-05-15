require "logstash/filters/base"
require "logstash/namespace"

require "csv"

# CSV filter. Takes an event field containing CSV data, parses it,
# and stores it as individual fields (can optionally specify the names).
class LogStash::Filters::CSV < LogStash::Filters::Base
  config_name "csv"
  plugin_status "beta"

  # The CSV data in the value of the source field will be expanded into a
  # datastructure.
  config :source, :validate => :string, :default => '@message'

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

    # Nothing to do here

  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running csv filter", :event => event)

    matches = 0

    key = @source
    dest = @target

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
    end # if event

    @logger.debug("Event after csv filter", :event => event)

  end # def filter

end # class LogStash::Filters::Csv

