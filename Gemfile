source :rubygems

def jruby?
  return RUBY_ENGINE == "jruby"
end

gem "cabin", "0.1.3" # for logging. apache 2 license
gem "bunny" # for amqp support, MIT-style license
gem "uuidtools" # for naming amqp queues, License ???
gem "filewatch", "0.3.0"  # for file tailing, BSD License
gem "jls-grok", "0.9.2" # for grok filter, BSD License
jruby? and gem "jruby-elasticsearch", "0.0.11" # BSD License
gem "stomp" # for stomp protocol, Apache 2.0 License
gem "json" # Ruby license
gem "awesome_print" # MIT License
jruby? and gem "jruby-openssl" # For enabling SSL support, CPL/GPL 2.0

gem "minitest" # License: Ruby
gem "rack" # License: MIT
jruby? and gem "mizuno" # License: Apache 2.0
gem "sinatra" # License: MIT-style
gem "haml" # License: MIT
gem "sass" # License: MIT

# TODO(sissel): Put this into a group that's only used for monolith packaging
gem "mongo" # outputs/mongodb, License: Apache 2.0
gem "redis" # outputs/redis, License: MIT-style
gem "gelf" # outputs/gelf, # License: MIT-style
gem "statsd-ruby", "0.3.0" # outputs/statsd, # License: As-Is
gem "gmetric", "0.1.3" # outputs/ganglia, # License: MIT
gem "xmpp4r", "0.5" # outputs/xmpp, # License: As-Is
gem "gelfd", "0.1.0" #inputs/gelf, # License: Apache 2.0

gem "ffi-rzmq", "0.9.0"
gem "ruby-debug", "0.10.4"
gem "mocha", "0.10.0"
