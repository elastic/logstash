
require "logstash/namespace"

module LogStash::Filters
  def self.from_name(name, *args)
    # TODO(sissel): Add error handling
    # TODO(sissel): Allow plugin paths
    klass = name.capitalize

    # Load the class if we haven't already.
    require "logstash/filters/#{name}"

    # Get the class name from the Filters namespace and create a new instance.
    # for name == 'foo' this will call LogStash::Filters::Foo.new
    LogStash::Filters.const_get(klass).new(*args)
  end # def from_url
end # module LogStash::Filters
