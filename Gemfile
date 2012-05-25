source :rubygems

def jruby?
  return RUBY_ENGINE == "jruby"
end

gem "cabin", "0.4.1" # for logging. apache 2 license
gem "bunny" # for amqp support, MIT-style license
gem "uuidtools" # for naming amqp queues, License ???

gem "filewatch", "0.3.3"  # for file tailing, BSD License
gem "jls-grok", "0.10.6" # for grok filter, BSD License
gem "aws-sdk" # for AWS access: SNS and S3 log tailing.  Apache 2.0 License
gem "jruby-elasticsearch", "0.0.11", :platforms => :jruby # BSD License
gem "onstomp" # for stomp protocol, Apache 2.0 License
gem "json" # Ruby license
#gem "awesome_print" # MIT License
gem "jruby-openssl", :platforms => :jruby # For enabling SSL support, CPL/GPL 2.0
gem "mail" #outputs/email, # License: MIT License

gem "minitest" # License: Ruby
gem "rack" # License: MIT
gem "ftw", "~> 0.0.13"  # License: Apache 2.0
gem "sinatra" # License: MIT-style
gem "haml" # License: MIT
gem "sass" # License: MIT
gem "heroku" # License: MIT

# TODO(sissel): Put this into a group that's only used for monolith packaging
gem "mongo" # outputs/mongodb, License: Apache 2.0
gem "redis" # outputs/redis, License: MIT-style
gem "gelf" # outputs/gelf, # License: MIT-style
gem "statsd-ruby", "0.3.0" # outputs/statsd, # License: As-Is
gem "gmetric", "0.1.3" # outputs/ganglia, # License: MIT
gem "xmpp4r", "0.5" # outputs/xmpp, # License: As-Is
gem "gelfd", "0.2.0" #inputs/gelf, # License: Apache 2.0
jruby? and gem "jruby-win32ole" # inputs/eventlog, # License: JRuby

gem "ffi-rzmq", "0.9.0"
gem "ffi"

gem "riemann-client", "0.0.6" #outputs/riemann, License: MIT

group :test do
  gem "mocha"
  gem "shoulda"
end

# ruby-debug is broken in 1.9.x due, at a minimum, the following:
#    Installing rbx-require-relative (0.0.5)
#    Gem::InstallError: rbx-require-relative requires Ruby version ~> 1.8.7.
#
# ruby-debug wants linecache which wants rbx-require-relative which won't
# install under 1.9.x. I never use ruby-debug anyway, so, kill it.
#gem "ruby-debug", "0.10.4"
#gem "mocha", "0.10.0"
