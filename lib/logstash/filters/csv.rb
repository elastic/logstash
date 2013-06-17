require "logstash/filters/base"
require "logstash/namespace"

require "csv"

# CSV filter. Takes an event field containing CSV data, parses it,
# and stores it as individual fields (can optionally specify the names).
class LogStash::Filters::CSV < LogStash::Filters::Base
  config_name "csv"
  milestone 2

  # The CSV data in the value of the source field will be expanded into a
  # datastructure.
  config :source, :validate => :string, :default => "message"

  # Define a list of column names (in the order they appear in the CSV,
  # as if it were a header line). If this is not specified or there
  # are not enough columns specified, the default column name is "columnX"
  # (where X is the field number, starting from 1).
  config :columns, :validate => :array, :default => []

  # Define the column separator value. If this is not specified the default
  # is a comma ','
  # Optional.
  config :separator, :validate => :string, :default => ","

  # Define target for placing the data
  # Defaults to writing to the root of the event.
  config :target, :validate => :string

  public
  def register

    # Nothing to do here

  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running csv filter", :event => event)

    matches = 0

    if event[@source]
      if event[@source].is_a?(String)
        event[@source] = [event[@source]]
      end

      if event[@source].length > 1
        @logger.warn("csv filter only works on fields of length 1",
                     :source => @source, :value => event[@source],
                     :event => event)
        return
      end

      raw = event[@source].first
      begin
        values = CSV.parse_line(raw, :col_sep => @separator)

        if @target.nil?
          # Default is to write to the root of the event.
          dest = event
        else
          dest = event[@target] ||= {}
        end

        values.each_index do |i|
          field_name = @columns[i] || "column#{i+1}"
          dest[field_name] = values[i]
        end

        filter_matched(event)
      rescue => e
        event.tags << "_csvparsefailure"
        @logger.warn("Trouble parsing csv", :source => @source, :raw => raw,
                      :exception => e)
        return
      end # begin
    end # if event

    @logger.debug("Event after csv filter", :event => event)

  end # def filter

end # class LogStash::Filters::Csv

