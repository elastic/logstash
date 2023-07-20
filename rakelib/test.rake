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

# we need to call exit explicitly  in order to set the proper exit code, otherwise
# most common CI systems can not know whats up with this tests.

require 'pathname'

namespace "test" do
  desc "run the java unit tests"
  task "core-java" do
    exit(1) unless system('./gradlew clean javaTests')
  end

  desc "run the ruby unit tests"
  task "core-ruby" => "compliance" do
    exit 1 unless system(*default_spec_command)
  end

  desc 'run the ruby compliance tests'
  task 'compliance' do
    exit 1 unless system('bin/rspec', '-fd', '--patern', 'spec/compliance/**/*_spec.rb')
  end

  desc "run all core specs"
  task "core" => ["core-slow"]

  def default_spec_command
    ["bin/rspec", "-fd", "--pattern", "spec/unit/**/*_spec.rb,logstash-core/spec/**/*_spec.rb"]
  end

  desc "run all core specs"
  task "core-slow" do
    exit 1 unless system('./gradlew clean test')
  end

  desc "run core specs excluding slower tests like stress tests"
  task "core-fast" do
    exit 1 unless system(*(default_spec_command.concat(["--tag", "~stress_test"])))
  end

  desc "run all installed plugins specs"
  task "plugins" => "bootstrap" do
    plugins_to_exclude = ENV.fetch("EXCLUDE_PLUGIN", "").split(",")
    # the module LogStash::PluginManager requires the file `lib/pluginmanager/plugin_aliases.yml`,
    # that file is created during the bootstrap task
    require "pluginmanager/util"

    # grab all spec files using the live plugins gem specs. this allows correctly also running the specs
    # of a local plugin dir added using the Gemfile :path option. before this, any local plugin spec would
    # not be run because they were not under the vendor/bundle/jruby/2.0/gems path
    test_files = LogStash::PluginManager.find_plugins_gem_specs.map do |spec|
      if plugins_to_exclude.size > 0
        if !plugins_to_exclude.include?(Pathname.new(spec.gem_dir).basename.to_s)
          Rake::FileList[File.join(spec.gem_dir, "spec/{input,filter,codec,output}s/*_spec.rb")]
        end
      else
        Rake::FileList[File.join(spec.gem_dir, "spec/{input,filter,codec,output}s/*_spec.rb")]
      end
    end.flatten.compact

    # "--format=documentation"
    exit 1 unless system(*(["bin/rspec", "-fd", "--order", "rand"].concat(test_files)))
  end

  desc "install dev dependencies"
  task "install-core" => ["bootstrap", "plugin:install-development-dependencies"]

  desc "install default plugins and dev dependencies"
  task "install-default" => ["bootstrap", "plugin:install-default", "plugin:install-development-dependencies"]
end

task "test" => ["test:core"]
