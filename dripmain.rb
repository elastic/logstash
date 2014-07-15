# dripmain.rb is called by org.jruby.main.DripMain to further warm the JVM with any preloading
# that we can do to speedup future startup using drip.

# we are out of the application context here so setup the load path and gem paths
lib_path = File.expand_path(File.join(File.dirname(__FILE__), "./lib"))
$:.unshift(lib_path)

require "logstash/environment"
LogStash::Environment.set_gem_paths!

# typical required gems and libs
require "i18n"
I18n.enforce_available_locales = true
I18n.load_path << LogStash::Environment.locales_path("en.yml")
require "cabin"
require "stud/trap"
require "stud/task"
require "clamp"
require "rspec"
require "rspec/core/runner"

require "logstash/namespace"
require "logstash/program"
require "logstash/agent"
require "logstash/kibana"
require "logstash/util"
require "logstash/errors"
require "logstash/pipeline"
require "logstash/plugin"
