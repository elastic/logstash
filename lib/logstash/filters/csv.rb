# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"

require "csv"

# The CSV filter takes an event field containing CSV data, parses it,
# and stores it as individual fields (can optionally specify the names).
# This filter can also parse data with any separator, not just commas.
class LogStash::Filters::CSV < LogStash::Filters::Base
  config_name "csv"
  milestone 2

  # The CSV data in the value of the `source` field will be expanded into a
  # data structure.
  config :source, :validate => :string, :default => "message"

  # Define a list of column names (in the order they appear in the CSV,
  # as if it were a header line). If `columns` is not configured, or there
  # are not enough columns specified, the default column names are
  # "column1", "column2", etc. In the case that there are more columns
  # in the data than specified in this column list, extra columns will be auto-numbered:
  # (e.g. "user_defined_1", "user_defined_2", "column3", "column4", etc.)
  config :columns, :validate => :array, :default => []

  # Define the column separator value. If this is not specified, the default
  # is a comma ','.
  # Optional.
  config :separator, :validate => :string, :default => ","

  # Define the character used to quote CSV fields. If this is not specified
  # the default is a double quote '"'.
  # Optional.
  config :quote_char, :validate => :string, :default => '"'

  # Define target field for placing the data.
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
        values = CSV.parse_line(raw, :col_sep => @separator, :quote_char => @quote_char)

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
        event.tag "_csvparsefailure"
        @logger.warn("Trouble parsing csv", :source => @source, :raw => raw,
                      :exception => e)
        return
      end # begin
    end # if event

    @logger.debug("Event after csv filter", :event => event)

  end # def filter

end # class LogStash::Filters::Csv

