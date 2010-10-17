
require "logstash/namespace"
require "uri"

module LogStash::Outputs
  def self.from_url(url, &block)
    uri = URI.parse(url)
    # TODO(sissel): Add error handling
    # TODO(sissel): Allow plugin paths
    klass = uri.scheme.capitalize
    file = uri.scheme
    require "logstash/outputs/#{file}"
    LogStash::Outputs.const_get(klass).new(uri, &block)
  end # def from_url
end # module LogStash::Outputs
