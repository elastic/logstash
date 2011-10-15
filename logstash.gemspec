require File.join(File.dirname(__FILE__), "lib", "logstash", "version")  # For LOGSTASH_VERSION

Gem::Specification.new do |spec|
  files = []
  paths = %w{lib examples etc patterns}
  paths << "test/logstash/"
  paths << "test/logstash_test_runner.rb"
  paths << "test/standalone.sh"
  paths << "test/setup/elasticsearch/Makefile"
  paths.each do |path|
    if File.file?(path)
      files << path
    else
      files += Dir["#{path}/**/*"]
    end
  end

  #rev = %x{svn info}.split("\n").grep(/Revision:/).first.split(" ").last.to_i
  rev = Time.now.strftime("%Y%m%d%H%M%S")
  spec.name = "logstash"
  spec.version = LOGSTASH_VERSION
  spec.summary = "logstash - log and event management"
  spec.description = "scalable log and event management (search, archive, pipeline)"
  spec.license = "Apache License (2.0)"

  #spec.add_dependency("eventmachine-tail") # TODO(sissel): remove, not for jruby
  spec.add_dependency("json")

  # New for our JRuby stuff
  spec.add_dependency "bunny" # for amqp support
  spec.add_dependency "uuidtools" # for naming amqp queues
  spec.add_dependency "filewatch", "~> 0.2.3"  # for file tailing
  spec.add_dependency "jls-grok", "~> 0.9.0" # for grok filter
  spec.add_dependency "jruby-elasticsearch", "~> 0.0.11"
  spec.add_dependency "stomp" # for stomp protocol
  spec.add_dependency "json"
  spec.add_dependency "awesome_print"

  spec.add_dependency "rack"
  spec.add_dependency "mizuno"
  spec.add_dependency "sinatra"
  spec.add_dependency "haml"

  spec.add_dependency "mongo" # outputs/mongodb
  spec.add_dependency "gelf" # outputs/gelf
  spec.add_dependency "statsd-ruby" # outputs/statsd
  spec.add_dependency "gmetric" # outputs/ganglia
  spec.add_dependency "xmpp4r" # outputs/xmpp

  spec.add_dependency("bunny")
  spec.add_dependency("uuidtools")

  # For beanstalk://
  #spec.add_dependency("em-jack")

  spec.files = files
  spec.require_paths << "lib"
  spec.bindir = "bin"
  spec.executables << "logstash"
  spec.executables << "logstash-web"
  spec.executables << "logstash-test"

  spec.authors = ["Jordan Sissel", "Pete Fritchman"]
  spec.email = ["jls@semicomplete.com", "petef@databits.net"]
  spec.homepage = "http://logstash.net/"
end

