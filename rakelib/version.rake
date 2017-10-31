require 'yaml'

VERSION_FILE = "versions.yml"
README_FILE = "README.md"
INDEX_SHARED1_FILE = "docs/index-shared1.asciidoc"

def get_versions
  yaml_versions = YAML.safe_load(IO.read(VERSION_FILE))
  {
    "logstash" => yaml_versions["logstash"],
    "logstash-core" =>  yaml_versions["logstash-core"],
    "logstash-core-plugin-api" => yaml_versions["logstash-core-plugin-api"],
  }
end

# Update the version file, keeping the comments in tact
def update_version_file(old_version, new_version)
  versions_as_text = IO.read(VERSION_FILE)
  %w(logstash logstash-core logstash-core-plugin-api).each do |field|
    versions_as_text.gsub!(/(?<=#{field}: )#{old_version[field]}/, "#{new_version[field]}")
  end
  IO.write(VERSION_FILE, versions_as_text)
end

def update_index_shared1(old_version, new_version)
  index_shared1 = IO.read(INDEX_SHARED1_FILE)
  %w(logstash elasticsearch kibana).each do |field|
    index_shared1.gsub!(/(:#{field}_version:\s+)#{old_version['logstash']}/) { "#{$1}#{new_version['logstash']}" }
  end
  IO.write(INDEX_SHARED1_FILE, index_shared1)
end

def update_readme(old_version, new_version)
  readme = IO.read(README_FILE)
  readme.gsub!(/(logstash\-)#{old_version['logstash']}/) { "#{$1}#{new_version['logstash']}" }
  IO.write(README_FILE, readme)
end

namespace :version do
  desc "show version of core components"
  task :show do
    get_versions.each do |component, version|
      puts "#{component}: #{version}"
    end
  end

  desc "set version of logstash, logstash-core"
  task :set, [:version] => [:validate] do |t, args|
    new_version = {}
    get_versions.each do |component, version|
      # we just assume that, usually, all components except
      # "logstash-core-plugin-api" will be versioned together
      # so let's skip this one and have a separate task for it
      if component == "logstash-core-plugin-api"
        new_version[component] = version
      else
        new_version[component] = args[:version]
      end
    end
    old_version = YAML.safe_load(File.read(VERSION_FILE))
    update_index_shared1(old_version, new_version)
    update_readme(old_version, new_version)
    update_version_file(old_version, new_version)
  end

  desc "set version of logstash-core-plugin-api"
  task :set_plugin_api, [:version] => [:validate] do |t, args|
    hash = {}
    get_versions.each do |component, version|
      if component == "logstash-core-plugin-api"
        hash[component] = args[:version]
      else
        hash[component] = version
      end
    end
    update_version_file(hash)
  end

  task :validate, :version do |t, args|
    unless Regexp.new('^\d+\.\d+\.\d+(?:-\w+\d+)?$').match(args[:version])
      abort("Invalid version argument: \"#{args[:version]}\". Aborting...")
    end
  end

end
