require 'yaml'

def get_versions
  yaml_versions = YAML.safe_load(IO.read("versions.yml"))
  {
    "logstash" => {
      "location" => File.join("logstash-core", "lib", "logstash", "version.rb"),
      "yaml_version" => yaml_versions["logstash"],
      "current_version" => get_version(File.join("logstash-core", "lib", "logstash", "version.rb")),
    },
    "logstash-core" => {
      "location" => File.join("logstash-core", "lib", "logstash-core", "version.rb"),
      "yaml_version" => yaml_versions["logstash-core"],
      "current_version" => get_version(File.join("logstash-core", "lib", "logstash-core", "version.rb")),
    },
    "logstash-core-event" => {
      "location" => File.join("logstash-core-event", "lib", "logstash-core-event", "version.rb"),
      "yaml_version" => yaml_versions["logstash-core-event"],
      "current_version" => get_version(File.join("logstash-core-event", "lib", "logstash-core-event", "version.rb")),
    },
    "logstash-core-event-java" => {
      "location" => File.join("logstash-core-event-java", "lib", "logstash-core-event-java", "version.rb"),
      "yaml_version" => yaml_versions["logstash-core-event-java"],
      "current_version" => get_version(File.join("logstash-core-event-java", "lib", "logstash-core-event-java", "version.rb")),
    },
    "logstash-core-plugin-api" => {
      "location" => File.join("logstash-core-plugin-api", "lib", "logstash-core-plugin-api", "version.rb"),
      "yaml_version" => yaml_versions["logstash-core-plugin-api"],
      "current_version" => get_version(File.join("logstash-core-plugin-api", "lib", "logstash-core-plugin-api", "version.rb")),
    }
  }
end

def get_version(file)
  text = IO.read(file)
  version = text.match(/^[A-Z_]+ = "(.+?)"/)
  version[1]
end

namespace :version do

  desc "check if the versions.yml is out of sync with .gemspecs and other references"
  task :check do
    out_of_sync = get_versions.select do |component, metadata|
      metadata["yaml_version"] != metadata["current_version"]
    end
    if out_of_sync.any?
      out_of_sync.each do |component, metadata|
        puts "#{component} is out of sync. CURRENT: #{metadata['current_version']} | YAML: #{metadata['yaml_version']}"
      end
      exit(1)
    end
  end

  desc "push versions found in versions.yml to all component version locations"
  task :sync do
    versions = get_versions
    # update version.rb files
    versions.select do |component, metadata|
      next if metadata["yaml_version"] == metadata["current_version"]
      puts "Updating \"#{component}\" from \"#{metadata['current_version']}\" to \"#{metadata['yaml_version']}\""
      text = IO.read(metadata["location"])
      IO.write(metadata["location"], text.gsub(metadata["current_version"], metadata["yaml_version"]))
    end

    # update dependencies
    #
    # logstash-core depends on logstash-core-event-java
    # ./logstash-core/logstash-core.gemspec:  gem.add_runtime_dependency "logstash-core-event-java", "~> 5.0.0.dev"
    logstash_core_gemspec = File.join("logstash-core", "logstash-core.gemspec")
    logstash_core_event_java_version = versions['logstash-core-event-java']['yaml_version']
    text = IO.read(logstash_core_gemspec)
    IO.write(logstash_core_gemspec, text.sub(
      /  gem.add_runtime_dependency \"logstash-core-event-java\", \".+?\"/,
      "  gem.add_runtime_dependency \"logstash-core-event-java\", \"#{logstash_core_event_java_version}\""))

    # logstash-core-event-java depends on logstash-code
    # ./logstash-core-plugin-api/logstash-core-plugin-api.gemspec:  gem.add_runtime_dependency "logstash-core", "5.0.0.dev"
    logstash_core_plugin_api_gemspec = File.join("logstash-core-plugin-api", "logstash-core-plugin-api.gemspec")
    logstash_core_version = versions['logstash-core']['yaml_version']
    text = IO.read(logstash_core_plugin_api_gemspec)
    IO.write(logstash_core_plugin_api_gemspec, text.sub(
      /  gem.add_runtime_dependency \"logstash-core\", \".+?\"/,
      "  gem.add_runtime_dependency \"logstash-core\", \"#{logstash_core_version}\""))
  end

  desc "show version of core components"
  task :show do
    Rake::Task["version:sync"].invoke; Rake::Task["version:sync"].reenable
    get_versions.each do |component, metadata|
      puts "#{component}: #{metadata['yaml_version']}"
    end
  end

  desc "set version of logstash, logstash-core, logstash-core-event, logstash-core-event-java"
  task :set, [:version] => [:validate] do |t, args|
    hash = {}
    get_versions.each do |component, metadata|
      # we just assume that, usually, all components except
      # "logstash-core-plugin-api" will be versioned together
      # so let's skip this one and have a separate task for it
      if component == "logstash-core-plugin-api"
        hash[component] = metadata["yaml_version"]
      else
        hash[component] = args[:version]
      end
    end
    IO.write("versions.yml", hash.to_yaml)
    Rake::Task["version:sync"].invoke; Rake::Task["version:sync"].reenable
  end

  desc "set version of logstash-core-plugin-api"
  task :set_plugin_api, [:version] => [:validate] do |t, args|
    hash = {}
    get_versions.each do |component, metadata|
      if component == "logstash-core-plugin-api"
        hash[component] = args[:version]
      else
        hash[component] = metadata["yaml_version"]
      end
    end
    IO.write("versions.yml", hash.to_yaml)
    Rake::Task["version:sync"].invoke; Rake::Task["version:sync"].reenable
  end

  task :validate, :version do |t, args|
    unless Regexp.new('^\d+\.\d+\.\d+(?:-\w+\d+)?$').match(args[:version])
      abort("Invalid version argument: \"#{args[:version]}\". Aborting...")
    end
  end

end
