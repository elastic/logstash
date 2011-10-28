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

  spec.add_dependency "awesome_print" # MIT License
  spec.add_dependency "bunny" # for amqp support, MIT-style license
  spec.add_dependency "cabin", "0.1.3" # for logging. apache 2 license
  spec.add_dependency "filewatch", "~> 0.3.0"  # for file tailing, BSD License
  spec.add_dependency "gelfd", "~> 0.1.0" #inputs/gelf, # License: Apache 2.0
  spec.add_dependency "gelf" # outputs/gelf, # License: MIT-style
  spec.add_dependency "gmetric", "~> 0.1.3" # outputs/ganglia, # License: MIT
  spec.add_dependency "haml" # License: MIT
  spec.add_dependency "jls-grok", "0.9.0" # for grok filter, BSD License
  spec.add_dependency "jruby-elasticsearch", "~> 0.0.11" # BSD License
  spec.add_dependency "jruby-openssl" # For enabling SSL support, CPL/GPL 2.0
  spec.add_dependency "json" # Ruby license
  spec.add_dependency "minitest" # License: Ruby
  spec.add_dependency "mizuno" # License: Apache 2.0
  spec.add_dependency "mongo" # outputs/mongodb, License: Apache 2.0
  spec.add_dependency "rack" # License: MIT
  spec.add_dependency "redis" # outputs/redis, License: MIT-style
  spec.add_dependency "sass" # License: MIT
  spec.add_dependency "sinatra" # License: MIT-style
  spec.add_dependency "statsd-ruby", "~> 0.3.0" # outputs/statsd, # License: As-Is
  spec.add_dependency "stomp" # for stomp protocol, Apache 2.0 License
  spec.add_dependency "uuidtools" # for naming amqp queues, License ???
  spec.add_dependency "xmpp4r", "~> 0.5" # outputs/xmpp, # License: As-Is

  spec.add_dependency("ffi-rzmq")
  spec.add_dependency("ruby-debug")
  spec.add_dependency("mocha")

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

