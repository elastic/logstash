require "logstash/namespace"
require "logstash/ruby_fixes"
require "uri"

module LogStash::Inputs
  # Given a URL, try to load the class that supports it.
  # That is, if we have an input of "foo://blah/" then
  # we will try to load logstash/inputs/foo and will
  # expect a class LogStash::Inputs::Foo
  public
  def self.from_url(url, type, &block)
    # Assume file paths if we start with "/"
    url = "file://#{url}" if url.start_with?("/")

    uri = URI.parse(url)
    # TODO(sissel): Add error handling
    # TODO(sissel): Allow plugin paths
    klass = uri.scheme.capitalize
    file = uri.scheme.downcase
    require "logstash/inputs/#{file}"
    LogStash::Inputs.const_get(klass).new(uri, type, &block)
  end # def from_url
end # module LogStash::Inputs
