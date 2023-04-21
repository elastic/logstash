# encoding: utf-8

# Test the 
# - build (rspec), 
# - packaging (gem build)
# - and deploy (bin/logstash-plugin install)
# of a plugins inside the current Logstash, using its JRuby

require "open3"
require "set"

ENV['LOGSTASH_PATH'] = Dir.pwd
ENV['LOGSTASH_SOURCE'] = '1'

logstash_plugin_cli = ENV['LOGSTASH_PATH'] + "/bin/logstash-plugin"

# it has to be out of logstash local close else plugins' Gradle script
# would interfere with Logstash's one
base_folder = "/tmp"
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

  def git_clone
    if File.directory?(plugin_name)
      puts "#{plugin_name} already cloned locally"
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
    unless spec_result
      return false
    else
      return true
    end
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
      puts "Failed to install plugins:\n #{stdout}"
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

Dir.chdir(plugins_folder) do
  tier1_integrations = ["logstash-integration-jdbc", "logstash-integration-kafka", "logstash-integration-rabbitmq",
                        "logstash-integration-elastic_enterprise_search"]
  tier1_inputs = ["logstash-inputs-azure_event_hubs", "logstash-inputs-beats", "logstash-inputs-elasticsearch", "logstash-inputs-file",
                  "logstash-inputs-generator", "logstash-inputs-heartbeat", "logstash-inputs-http", "logstash-inputs-http_poller",
                  "logstash-inputs-redis", "logstash-inputs-s3", "logstash-inputs-stdin", "logstash-inputs-syslog", "logstash-inputs-udp",
                  "logstash-inputs-elastic_agent"]
  tier1_codecs = ["logstash-codec-avro", "logstash-codec-cef", "logstash-codec-es_bulk", "logstash-codec-json",
                  "logstash-codec-json_lines", "logstash-codec-line", "logstash-codec-multiline", "logstash-codec-plain",
                  "logstash-codec-rubydebug"]
  tier1_filters = ["logstash-filter-cidr", "logstash-filter-clone", "logstash-filter-csv", "logstash-filter-date", "logstash-filter-dissect",
                   "logstash-filter-dns", "logstash-filter-drop", "logstash-filter-elasticsearch", "logstash-filter-fingerprint",
                   "logstash-filter-geoip", "logstash-filter-grok", "logstash-filter-http", "logstash-filter-json", "logstash-filter-kv",
                   "logstash-filter-memcached", "logstash-filter-mutate", "logstash-filter-prune", "logstash-filter-ruby",
                   "logstash-filter-sleep", "logstash-filter-split", "logstash-filter-syslog_pri", "logstash-filter-translate",
                   "logstash-filter-truncate", "logstash-filter-urldecode", "logstash-filter-useragent", "logstash-filter-uuid",
                   "logstash-filter-xml"]
  tier1_outputs = ["logstash-output-elasticsearch", "logstash-output-email", "logstash-output-file", "logstash-output-http",
                   "logstash-output-redis", "logstash-output-s3", "logstash-output-stdout", "logstash-output-tcp", "logstash-output-udp"]

  tier2_inputs = ["logstash-input-couchdb_changes", "logstash-input-gelf", "logstash-input-graphite", "logstash-input-jms",
                  "logstash-input-snmp", "logstash-input-sqs", "logstash-input-twitter"]
  tier2_codecs = ["logstash-codec-collectd", "logstash-codec-dots", "logstash-codec-fluent", "logstash-codec-graphite",
                  "logstash-codec-msgpack", "logstash-codec-netflow" ]
  tier2_filters = ["logstash-filter-aggregate", "logstash-filter-de_dot", "logstash-filter-throttle"]
  tier2_outputs = ["logstash-output-csv", "logstash-output-graphite"]

#   plugins = tier1_integrations
  plugins = ["logstash-filter-cidr"]

  plugins.each do |plugin_name|
    plugin = Plugin.new(plugins_folder, plugin_name)
    plugin.git_clone

    Dir.chdir(plugin_name) do
      unless plugin.execute_rspec
        failed_plugins << FailureDetail.new(plugin_name, :unit_test)
        next
      end  

      # build the gem and install into Logstash
      gem_file = plugin.build_gem
      unless gem_file
        #puts "inserted into failed, because no gem file exists"
        failed_plugins << FailureDetail.new(plugin_name, :gem_build)
        next
      end

      # install the plugin
      unless plugin.install_gem(gem_file)
        #puts "inserted into failed, because the gem can't be installed"
        failed_plugins << FailureDetail.new(plugin_name, :gem_install)
        next
      end
    end
  end
end

puts "########################################"
puts " Failed plugins:"
puts "----------------------------------------"
failed_plugins.each {|failure| puts "- #{failure}"}
puts "########################################"



