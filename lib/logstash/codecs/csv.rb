require "csv"
require "logstash/codecs/base"

# CSV output.
#
# Write events to disk in CSV or other delimited format
# Based on the file output, many config values are shared
# Uses the Ruby csv library internally
class LogStash::Codecs::CSV < LogStash::Codecs::Base

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
    @csv_options = Hash[@csv_options.map{|(k,v)|[k.to_sym, v]}]
  end

  public
  def decode(data)
    raise "Not implemented"
  end # def decode

  public
  def encode(data)
    csv_values = @fields.map {|name| get_value(name, data)}
    @on_event.call(csv_values.to_csv(@csv_options) + "\n")
  end # def encode

  private
  def get_value(name, event)
    val = event[name]
    case val
      when Hash
        return val.to_json
      else
        return val
    end
  end
end # class LogStash::Codec::CSV

