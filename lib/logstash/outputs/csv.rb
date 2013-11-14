require "csv"
require "logstash/namespace"
require "logstash/outputs/file"

class LogStash::Outputs::CSV < LogStash::Outputs::File
  config_name "csv"
  milestone 1
  config :fields, :validate => :array, :required => true
  config :csv_options, :validate => :hash, :required => false, :default => Hash.new

  public
  def register
    super
    @csv_options = Hash[@csv_options.map{|(k,v)|[k.to_sym, v]}]
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
    case val
      when Hash
        return val.to_json
      else
        return val
    end
  end
end # class LogStash::Outputs::CSV

