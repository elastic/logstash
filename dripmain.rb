# dripmain.rb is called by org.jruby.main.DripMain to further warm the JVM with any preloading
# that we can do to speedup future startup using drip.

require_relative "lib/bootstrap/environment"
LogStash::Bundler.setup!({:without => [:build]})
require "logstash-core"

# typical required gems and libs
require "logstash/environment"
LogStash::Environment.load_locale!

require "cabin"
require "stud/trap"
require "stud/task"
require "clamp"
require "rspec"
require "rspec/core/runner"

require "logstash/namespace"
require "logstash/program"
require "logstash/agent"
require "logstash/util"
require "logstash/errors"
require "logstash/pipeline"
require "logstash/plugin"
