# encoding: utf-8

# Test the
# - build (rspec),
# - packaging (gem build)
# - and deploy (bin/logstash-plugin install)
# of a plugins inside the current Logstash, using its JRuby
# Usage example:
# bin/ruby ci/test_supported_plugins.rb -p logstash-integration-jdbc
# bin/ruby ci/test_supported_plugins.rb -t tier1 -k input,codec,integration
#
# The script uses OS's temp folder unless the environment variable LOGSTASH_PLUGINS_TMP is specified.
# The path of such variable should be absolute.

require "open3"
require "set"
require 'optparse'

ENV['LOGSTASH_PATH'] = File.expand_path('..', __dir__)
ENV['LOGSTASH_SOURCE'] = '1'

logstash_plugin_cli = ENV['LOGSTASH_PATH'] + "/bin/logstash-plugin"

# it has to be out of logstash local close else plugins' Gradle script
# would interfere with Logstash's one
base_folder =  ENV['LOGSTASH_PLUGINS_TMP'] || (require 'tmpdir'; Dir.tmpdir)
puts "Using #{base_folder} as temporary clone folder"
plugins_folder = File.join(base_folder, "plugin_clones")
unless File.directory?(plugins_folder)
  Dir.mkdir(plugins_folder)
end

class Plugin
  attr_reader :plugins_folder, :plugin_name, :plugin_base_folder

  def initialize(plugins_folder, plugin_name)
    @plugin_name = plugin_name
    @plugins_folder = plugins_folder
    @plugin_base_folder = "#{plugins_folder}/#{plugin_name}"
  end

  def git_retrieve
    if File.directory?(plugin_name)
      puts "#{plugin_name} already cloned locally, proceed with updating..."
      Dir.chdir(plugin_name) do
        system("git restore -- .")
        puts "Cleaning following files"
        system("git clean -n ")
        puts "Proceed with cleaning"
        system("git clean -Xf")
      end
      puts "#{plugin_name} updated"
      return
    end

    puts "#{plugin_name} local clone doesn't exist, cloning..."

    plugin_repository = "git@github.com:logstash-plugins/#{plugin_name}.git"
    unless system("git clone #{plugin_repository}")
      puts "Can't clone #{plugin_repository}"
      exit 1
    end
    puts "#{plugin_name} cloned"
  end

  # return true if successed
  def execute_rspec
    if File.exists?("#{plugin_base_folder}/build.gradle")
      system("#{plugin_base_folder}/gradlew vendor")
    end
    system("#{ENV['LOGSTASH_PATH']}/bin/ruby -S bundle install")
    spec_result = system("#{ENV['LOGSTASH_PATH']}/bin/ruby -S bundle exec rspec")
    #puts "DNABG>> spec_result #{spec_result}"
    return spec_result ? true : false
  end

  # Return nil in case of error or the file name of the generated gem file
  def build_gem
    system("gem build #{plugin_name}.gemspec")

    gem_name = Dir.glob("#{plugin_name}*.gem").first
    unless gem_name
      puts "**error** gem not generated for plugin #{plugin_name}"
      return nil
    end

    gem_file = File.join(plugin_base_folder, gem_name)
    puts "gem_file generated: #{gem_file}"
    gem_file
  end

  def install_gem(gem_file)
    logstash_plugin_cli = ENV['LOGSTASH_PATH'] + "/bin/logstash-plugin"
    stdout, stderr, status = Open3.capture3("#{logstash_plugin_cli} install #{gem_file}")
    reg_exp = /Installing .*\nInstallation successful$/
    if status != 0 && !reg_exp.match(stdout)
      puts "Failed to install plugins:\n stdout:\n #{stdout} \nstderr:\n #{stderr}"
      return false
    else
      puts "plugin #{plugin_name} successfully installed"
      #system("#{logstash_plugin_cli} remove #{gem_name}")
      return true
    end
  end
end

# reason could be a symbol, describing the phase that broke:
# :unit_test, :gem_build, :gem_install
FailureDetail = Struct.new(:plugin_name, :reason)

# contains set of FailureDetail
failed_plugins = [].to_set

PLUGIN_DEFINITIONS = {
  :tier1 => {
    :input => ["logstash-input-azure_event_hubs", "logstash-input-beats", "logstash-input-elasticsearch", "logstash-input-file",
               "logstash-input-generator", "logstash-input-heartbeat", "logstash-input-http", "logstash-input-http_poller",
               "logstash-input-redis", "logstash-input-s3", "logstash-input-stdin", "logstash-input-syslog", "logstash-input-udp",
               "logstash-input-elastic_agent"],
    :codec => ["logstash-codec-avro", "logstash-codec-cef", "logstash-codec-es_bulk", "logstash-codec-json",
               "logstash-codec-json_lines", "logstash-codec-line", "logstash-codec-multiline", "logstash-codec-plain",
               "logstash-codec-rubydebug"],
    :filter => ["logstash-filter-cidr", "logstash-filter-clone", "logstash-filter-csv", "logstash-filter-date", "logstash-filter-dissect",
                "logstash-filter-dns", "logstash-filter-drop", "logstash-filter-elasticsearch", "logstash-filter-fingerprint",
                "logstash-filter-geoip", "logstash-filter-grok", "logstash-filter-http", "logstash-filter-json", "logstash-filter-kv",
                "logstash-filter-memcached", "logstash-filter-mutate", "logstash-filter-prune", "logstash-filter-ruby",
                "logstash-filter-sleep", "logstash-filter-split", "logstash-filter-syslog_pri", "logstash-filter-translate",
                "logstash-filter-truncate", "logstash-filter-urldecode", "logstash-filter-useragent", "logstash-filter-uuid",
                "logstash-filter-xml"],
    :output => ["logstash-output-elasticsearch", "logstash-output-email", "logstash-output-file", "logstash-output-http",
                "logstash-output-redis", "logstash-output-s3", "logstash-output-stdout", "logstash-output-tcp", "logstash-output-udp"],
    :integration => ["logstash-integration-jdbc", "logstash-integration-kafka", "logstash-integration-rabbitmq",
                     "logstash-integration-elastic_enterprise_search"]
  },
  :tier2 => {
    :input => ["logstash-input-couchdb_changes", "logstash-input-gelf", "logstash-input-graphite", "logstash-input-jms",
                  "logstash-input-snmp", "logstash-input-sqs", "logstash-input-twitter"],
    :codec => ["logstash-codec-collectd", "logstash-codec-dots", "logstash-codec-fluent", "logstash-codec-graphite",
                  "logstash-codec-msgpack", "logstash-codec-netflow"],
    :filter => ["logstash-filter-aggregate", "logstash-filter-de_dot", "logstash-filter-throttle"],
    :output => ["logstash-output-csv", "logstash-output-graphite"]
  }
}

def validate_options!(options)
  raise "plugin and tiers or kinds can't be specified at the same time" if (options[:tiers] || options[:kinds]) && options[:plugin]

  options[:tiers].map! { |v| v.to_sym } if options[:tiers]
  options[:kinds].map! { |v| v.to_sym } if options[:kinds]

  raise "Invalid tier name expected tier1 or tier2" if options[:tiers] && !(options[:tiers] - [:tier1, :tier2]).empty?
  raise "Invalid kind name expected input, codec, filter, output, integration" if options[:kinds] && !(options[:kinds] - [:input, :codec, :filter, :output, :integration]).empty?
end

# @param tiers array of labels
# @param kinds array of labels
def select_by_tiers_and_kinds(tiers, kinds)
  selected = []
  tiers.each do |tier|
    kinds.each do |kind|
      selected = selected + PLUGIN_DEFINITIONS[tier].fetch(kind, [])
    end
  end
  selected
end

def select_plugins_by_opts(options)
  select_plugins = []
  if options[:plugin]
    select_plugins << options[:plugin]
  else
    selected_tiers = options.fetch(:tiers, [:tier1, :tier2])
    selected_kinds = options.fetch(:kinds, [:input, :codec, :filter, :output, :integration])
    select_plugins = select_plugins + select_by_tiers_and_kinds(selected_tiers, selected_kinds)
  end
  select_plugins
end

def snapshot_logstash_artifacts!
  stdout, stderr, status = Open3.capture3("git add --force -- Gemfile Gemfile.lock vendor/bundle")
  if status != 0
    puts "Error snapshotting Logstash on path: #{Dir.pwd}"
    puts stderr
    exit 1
  end
end

def cleanup_logstash_snapshot
  system("git restore --staged -- Gemfile Gemfile.lock vendor/bundle")
end

def restore_logstash_from_snapshot
  system("git restore -- Gemfile Gemfile.lock vendor/bundle")
  system("git clean -Xf -- Gemfile Gemfile.lock vendor/bundle")
end

def setup_logstash_for_development
  system("./gradlew installDevelopmentGems")
end

option_parser = OptionParser.new do |opts|
  opts.on '-t', '--tiers tier1, tier2', Array, 'Use to select which tier to test. If no provided mean "all"'
  opts.on '-k', '--kinds input, codec, filter, output', Array, 'Use to select which kind of plugin to test. If no provided mean "all"'
  opts.on '-pPLUGIN', '--plugin=PLUGIN', 'Use to select a specific plugin, conflict with either -t and -k'
  opts.on '-h', '--halt', 'Halt immediately on first error'
end
options = {}
option_parser.parse!(into: options)

validate_options!(options)

plugins = select_plugins_by_opts(options)

setup_logstash_for_development

# save to local git for test isolation
snapshot_logstash_artifacts!

plugins.each do |plugin_name|
   restore_logstash_from_snapshot

   Dir.chdir(plugins_folder) do
    plugin = Plugin.new(plugins_folder, plugin_name)
    plugin.git_retrieve

    status = Dir.chdir(plugin_name) do
      unless plugin.execute_rspec
        failed_plugins << FailureDetail.new(plugin_name, :unit_test)
        break :error
      end

      # build the gem and install into Logstash
      gem_file = plugin.build_gem
      unless gem_file
        #puts "inserted into failed, because no gem file exists"
        failed_plugins << FailureDetail.new(plugin_name, :gem_build)
        break :error
      end

      # install the plugin
      unless plugin.install_gem(gem_file)
        #puts "inserted into failed, because the gem can't be installed"
        failed_plugins << FailureDetail.new(plugin_name, :gem_install)
        break :error
      end
      :success
    end

    # any of the verification subtask terminated with error
    if status == :error
      # break looping on plugins if immediate halt
      break if options[:halt]
    end
  end
end

# restore original git status to avoid to accidentally commit build artifacts
cleanup_logstash_snapshot

if failed_plugins
  puts "########################################"
  puts " Failed plugins:"
  puts "----------------------------------------"
  failed_plugins.each {|failure| puts "- #{failure}"}
  puts "########################################"
else
  puts "NO ERROR ON PLUGINS!"
end
