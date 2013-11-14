require "csv"
require "logstash/namespace"
require "logstash/outputs/file"

class LogStash::Outputs::CSV < LogStash::Outputs::File
  config_name "csv"
  milestone 1
  config :fields, :validate => :array, :required => true

  public 
  def receive(event)
  return unless output?(event)
  path = event.sprintf(@path)
  fd = open(path)
  csv_values = @fields.map {|name| event[name]}
  fd.write(csv_values.to_csv)
  
  flush(fd)
  close_stale_files


  end #def receive
end # class LogStash::Outputs::CSV

