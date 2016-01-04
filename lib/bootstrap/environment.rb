# encoding: utf-8
# bootstrap.rb contains the minimal code to be able to launch Bundler to eventually be able
# to retrieve the core code in the logstash-core gem which can live under different paths
# depending on the launch context (local dev, packaged, etc)

require_relative "bundler"
require_relative "rubygems"

module LogStash
  module Environment
    extend self

    # also set the env LOGSTASH_HOME
    LOGSTASH_HOME = ENV["LOGSTASH_HOME"] = ::File.expand_path(::File.join(__FILE__, "..", "..", ".."))

    BUNDLE_DIR = ::File.join(LOGSTASH_HOME, "vendor", "bundle")
    GEMFILE_PATH = ::File.join(LOGSTASH_HOME, "Gemfile")
    LOCAL_GEM_PATH = ::File.join(LOGSTASH_HOME, 'vendor', 'local_gems')
    CACHE_PATH = File.join(LOGSTASH_HOME, "vendor", "cache")

    # @return [String] the ruby version string bundler uses to craft its gem path
    def gem_ruby_version
      RbConfig::CONFIG["ruby_version"]
    end

    # @return [String] major.minor ruby version, ex 1.9
    def ruby_abi_version
      RUBY_VERSION[/(\d+\.\d+)(\.\d+)*/, 1]
    end

    # @return [String] jruby, ruby, rbx, ...
    def ruby_engine
      RUBY_ENGINE
    end

    def windows?
      ::Gem.win_platform?
    end

    def jruby?
      @jruby ||= !!(RUBY_PLATFORM == "java")
    end

    def logstash_gem_home
      ::File.join(BUNDLE_DIR, ruby_engine, gem_ruby_version)
    end

    def vendor_path(path)
      return ::File.join(LOGSTASH_HOME, "vendor", path)
    end

    def pattern_path(path)
      return ::File.join(LOGSTASH_HOME, "patterns", path)
    end

  end
end

def flatten_hash(h,f="",g={})
  return g.update({ f => h }) unless h.is_a? Hash
  if f.empty?
    h.each { |k,r| flatten_hash(r,k,g) }
  else
    h.each { |k,r| flatten_hash(r,"#{f}.#{k}",g) }
  end
  g
end

def flatten_arguments(hash)
  args = []
  hash.each do |key, value|
    next if value.nil?
    if value == true
      args << "--#{key}"
    elsif value == false
      args << "--no-#{key}"
    else
      args << "--#{key}"
      args << value
    end
  end
  args
end

# when launched as a script, not require'd, (currently from bin/logstash and bin/logstash-plugin) the first
# argument is the path of a Ruby file to require and a LogStash::Runner class is expected to be
# defined and exposing the LogStash::Runner#main instance method which will be called with the current ARGV
# currently lib/logstash/runner.rb and lib/pluginmanager/main.rb are called using this.
if $0 == __FILE__
  LogStash::Bundler.setup!({:without => [:build, :development]})
  require ARGV.shift

  if settings = YAML.parse(IO.read("settings.yml"))
    settings = settings.to_ruby
    flat_settings_hash = flatten_hash(settings)
    settings_array = flatten_arguments(flat_settings_hash)
  else
    settings_array = []
  end

  # TODO deprecate these arguments in the next major version. use -i only
  if ARGV == ["irb"] || ARGV == ["pry"]
    puts "Warn: option \"#{ARGV.first}\" is deprecated, use \"-i #{ARGV.first}\" or \"--interactive=#{ARGV.first}\" instead"
    exit_status = LogStash::Runner.run("bin/logstash", ["--interactive", ARGV.first])
  else
    puts "Arguments from \'settings.yml\' file: #{settings_array}"
    puts "Arguments from command line: #{ARGV}"
    # The Clamp library supports specifying the same argument multiple times
    # and it keeps the   in an array. So in order for cli args to override
    # the settings.yml args we can do `settings_array + ARGV`
    exit_status = LogStash::Runner.run("bin/logstash", settings_array + ARGV)
  end
  exit(exit_status || 0)
end
