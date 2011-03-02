require "logstash/namespace"
require "uri"

module LogStash::Inputs
  public
  def self.from_name(type, configs, output_queue)
    klass = type.capitalize
    file = type.downcase
    require "logstash/inputs/#{file}"
    LogStash::Inputs.const_get(klass).new(configs, output_queue)
  end # def from_name
end # module LogStash::Inputs
