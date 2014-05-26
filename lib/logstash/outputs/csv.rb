require "csv"
require "logstash/namespace"
require "logstash/outputs/file"
require "logstash/json"

# CSV output.
#
# Write events to disk in CSV or other delimited format
# Based on the file output, many config values are shared
# Uses the Ruby csv library internally
class LogStash::Outputs::CSV < LogStash::Outputs::File

  config_name "csv"
  milestone 1

  # The field names from the event that should be written to the CSV file.
  # Fields are written to the CSV in the same order as the array.
  # If a field does not exist on the event, an empty string will be written.
  # Supports field reference syntax eg: `fields => ["field1", "[nested][field]"]`.
  config :fields, :validate => :array, :required => true

  # Options for CSV output. This is passed directly to the Ruby stdlib to\_csv function.
  # Full documentation is available here: [http://ruby-doc.org/stdlib-2.0.0/libdoc/csv/rdoc/index.html].
  # A typical use case would be to use alternative column or row seperators eg: `csv_options => {"col_sep" => "\t" "row_sep" => "\r\n"}` gives tab seperated data with windows line endings
  config :csv_options, :validate => :hash, :required => false, :default => Hash.new

  public
  def register
    super
    @csv_options = Hash[@csv_options.map{|(k, v)|[k.to_sym, v]}]
  end

  public
  def receive(event)
    return unless output?(event)
    path = event.sprintf(@path)
    fd = open(path)
    csv_values = @fields.map {|name| get_value(name, event)}
    fd.write(csv_values.to_csv(@csv_options))

    flush(fd)
    close_stale_files
  end #def receive

  private
  def get_value(name, event)
    val = event[name]
    val.is_a?(Hash) ? LogStash::Json.dump(val) : val
  end
end # class LogStash::Outputs::CSV

