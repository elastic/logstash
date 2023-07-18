# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'yaml'

VERSION_FILE = "versions.yml"
README_FILE = "README.md"
INDEX_SHARED1_FILE = "docs/index.asciidoc"

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

def update_lock_release_file(old_version, new_version)
  lock_file = Dir.glob('Gemfile*.lock.release').first
  unless lock_file
    warn "Gemfile*.lock.release missing - skipping version update"
    return
  end
  old_version = old_version['logstash-core']
  new_version = new_version['logstash-core']
  versions_as_text = IO.read(lock_file)
  #      logstash-core (= 7.16.0)
  versions_as_text.sub!(/logstash-core \(=\s?(#{old_version})\)/) { |m| m.sub(old_version, new_version) }
  #    logstash-core (7.16.0-java)
  versions_as_text.sub!(/logstash-core \((#{old_version})-java\)/) { |m| m.sub(old_version, new_version) }
  IO.write(lock_file, versions_as_text)
end

def update_index_shared1(new_version)
  index_shared1 = IO.read(INDEX_SHARED1_FILE)
  old_version = index_shared1.match(':logstash_version:\s+(?<logstash_version>\d[.]\d[.]\d.*)')[:logstash_version]
  %w(logstash elasticsearch kibana).each do |field|
    index_shared1.gsub!(/(:#{field}_version:\s+)#{old_version}/) { "#{$1}#{new_version}" }
  end
  IO.write(INDEX_SHARED1_FILE, index_shared1)
end

def update_readme(old_version, new_version)
  readme = IO.read(README_FILE)
  readme.gsub!(/(logstash\-(oss\-)?)#{old_version['logstash']}/) { "#{$1}#{new_version['logstash']}" }
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
    update_readme(old_version, new_version)
    update_version_file(old_version, new_version)
    update_lock_release_file(old_version, new_version)
  end

  desc "set stack version referenced in docs"
  task :set_doc_version, [:version] => [:validate] do |t, args|
    update_index_shared1(args[:version])
  end

  desc "set version of logstash-core-plugin-api"
  task :set_plugin_api, [:version] => [:validate] do |t, args|
    new_version = {}
    get_versions.each do |component, version|
      if component == "logstash-core-plugin-api"
        new_version[component] = args[:version]
      else
        new_version[component] = version
      end
    end
    old_version = YAML.safe_load(File.read(VERSION_FILE))
    update_version_file(old_version, new_version)
  end

  task :validate, :version do |t, args|
    unless Regexp.new('^\d+\.\d+\.\d+(?:-\w+\d+)?$').match(args[:version])
      abort("Invalid version argument: \"#{args[:version]}\". Aborting...")
    end
  end
end
