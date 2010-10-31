
require "logstash/namespace"
require "uri"

module LogStash::Inputs
  def self.from_url(url, type, &block)
    # Assume file paths if we start with "/"
    url = "file://#{url}" if url.start_with?("/")

    uri = URI.parse(url)
    # TODO(sissel): Add error handling
    # TODO(sissel): Allow plugin paths
    klass = uri.scheme.capitalize
    file = uri.scheme
    require "logstash/inputs/#{file}"
    LogStash::Inputs.const_get(klass).new(uri, type, &block)
  end # def from_url
end # module LogStash::Inputs
