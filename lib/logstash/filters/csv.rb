require "logstash/filters/base"
require "logstash/namespace"

require "csv"

# CSV filter. Takes an event field containing CSV data, parses it,
# and stores it as individual fields (can optionally specify the names).
class LogStash::Filters::Csv < LogStash::Filters::Base
  config_name "csv"
  plugin_status "beta"

  # Config for csv is:
  #   "source => dest".
  # The CSV data in the value of the source field will be expanded into a
  # datastructure in the "dest" field.  Note: if the "dest" field
  # already exists, it will be overridden.
  config /[A-Za-z0-9_-]+/, :validate => :string

  # Define a list of field names (in the order they appear in the CSV,
  # as if it were a header line). If this is not specified or there
  # are not enough fields specified, the default field name is "fieldN"
  # (where N is the field number, starting from 1).
  # Optional.
  config :fields, :validate => :array, :default => []

  public
  def register
    @csv = {}

    @config.each do |field, dest|
      next if (RESERVED + ["fields"]).member?(field)

      @csv[field] = dest
    end
  end # def register

  public
  def filter(event)
    return unless filter?(event)

    @logger.debug("Running csv filter", :event => event)

    matches = 0
    @csv.each do |key, dest|
      if event.fields[key]
        if event.fields[key].is_a?(String)
          event.fields[key] = [event.fields[key]]
        end

        if event.fields[key].length > 1
          @logger.warn("csv filter only works on fields of length 1",
                       :key => key, :value => event.fields[key],
                       :event => event)
          next
        end

        raw = event.fields[key].first
        begin
          values = CSV.parse_line(raw)
          data = {}
          values.each_index do |i|
            field_name = @fields[i] || "field#{i+1}"
            data[field_name] = values[i]
          end

          event.fields[dest] = data

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
