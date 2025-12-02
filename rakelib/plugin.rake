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

require_relative "default_plugins"
require 'rubygems'
require 'shellwords'

require 'bootstrap/environment'

namespace "plugin" do
  def install_plugins(*args)
    require_relative "../lib/pluginmanager/main"
    LogStash::PluginManager::Main.run("bin/logstash-plugin", ["install"] + args)
  end

  def remove_plugin(plugin, *more_plugins)
    require_relative "../lib/pluginmanager/main"
    LogStash::PluginManager::Main.run("bin/logstash-plugin", ["remove", plugin] + more_plugins)
  end

  def list_plugins(search=nil, expand: nil, verbose: nil)
    require_relative "../lib/pluginmanager/main"
    args = []
    args << "--verbose" if verbose
    args << search unless search.nil?

    stdout = invoke_plugin_manager!("list", *args)

    stdout.lines.select do |line|
      # STDOUT pollution removal needed until 8.19 and 9.1
      # https://github.com/elastic/logstash/pull/17125
      next false if line.match?(/^Using (system java|bundled JDK|LS_JAVA_HOME defined java)/)
      
      # post-execution filtration is needed until 8.19 and 9.1
      # when list --[no-]expand flag is supported, use it instead
      # https://github.com/elastic/logstash/pull/17124
      expand || line.match?(/^[a-z]/)
    end.map(&:chomp)
  end

  # the plugin manager's list command (and possibly others)
  def invoke_plugin_manager!(command, *args)
    plugin_manager_bin = Pathname.new(LogStash::Environment::LOGSTASH_HOME) / "bin" / "logstash-plugin"
    stdout_and_stderr = %x(#{Shellwords.escape(plugin_manager_bin)} #{Shellwords.join([command]+args)} 2>&1)
    unless $?.success?
      fail "ERROR INVOKING PLUGIN MANAGER: #{stdout_and_stderr}"
    end
    stdout_and_stderr
  end

  task "install-base" => "bootstrap" do
    puts("[plugin:install-base] Installing base dependencies")
    install_plugins("--development",  "--preserve")
    task.reenable # Allow this task to be run again
  end

  def remove_lockfile
    if ::File.exist?(LogStash::Environment::LOCKFILE)
      ::File.delete(LogStash::Environment::LOCKFILE)
    end
  end

  task "install-development-dependencies" => "bootstrap" do
    puts("[plugin:install-development-dependencies] Installing development dependencies")
    install_plugins("--development",  "--preserve")
    install_plugins("--preserve", *LogStash::RakeLib::CORE_SPECS_PLUGINS)

    task.reenable # Allow this task to be run again
  end

  task "install", :name do |task, args|
    name = args[:name]
    puts("[plugin:install] Installing plugin: #{name}")
    install_plugins("--no-verify", "--preserve", name)

    task.reenable # Allow this task to be run again
  end # task "install"

  task "clean-duplicate-gems" do
    shared_gems_path = File.join(LogStash::Environment::LOGSTASH_HOME,
                                  'vendor/jruby/lib/ruby/gems/shared/gems')
    default_gemspecs_path = File.join(LogStash::Environment::LOGSTASH_HOME,
                                       'vendor/jruby/lib/ruby/gems/shared/specifications/default')
    bundle_gems_path = File.join(LogStash::Environment::BUNDLE_DIR,
                                  'jruby/*/gems')

    # "bundled" gems in jruby
    # https://github.com/jruby/jruby/blob/024123c29d73b672d50730117494f3e4336a0edb/lib/pom.rb#L108-L152
    shared_gem_names = Dir.glob(File.join(shared_gems_path, '*')).map do |path|
      match = File.basename(path).match(/^(.+?)-\d+/)
      match ? match[1] : nil
    end.compact

    # "default" gems in jruby/ruby
    # https://github.com/jruby/jruby/blob/024123c29d73b672d50730117494f3e4336a0edb/lib/pom.rb#L21-L106
    default_gem_names = Dir.glob(File.join(default_gemspecs_path, '*.gemspec')).map do |path|
      match = File.basename(path).match(/^(.+?)-\d+/)
      match ? match[1] : nil
    end.compact

    # gems we explicitly manage with bundler (we always want these to take precedence)
    bundle_gem_names = Dir.glob(File.join(bundle_gems_path, '*')).map do |path|
      match = File.basename(path).match(/^(.+?)-\d+/)
      match ? match[1] : nil
    end.compact

    shared_duplicates = shared_gem_names & bundle_gem_names
    default_duplicates = default_gem_names & bundle_gem_names
    all_duplicates = (shared_duplicates + default_duplicates).uniq

    puts("[plugin:clean-duplicate-gems] Removing duplicate gems: #{all_duplicates.sort.join(', ')}")

    # Remove shared/bundled gem duplicates
    shared_duplicates.each do |gem_name|
      FileUtils.rm_rf(Dir.glob("#{shared_gems_path}/#{gem_name}-*"))
      FileUtils.rm_rf(Dir.glob("#{shared_gems_path}/../specifications/#{gem_name}-*.gemspec"))
    end

    # Remove default gem gemspecs only
    default_duplicates.each do |gem_name|
      # For stdlib default gems we only remove the gemspecs as removing the source code
      # files results in code loading errors and ruby warnings
      FileUtils.rm_rf(Dir.glob("#{default_gemspecs_path}/#{gem_name}-*.gemspec"))
    end

    task.reenable
  end


  task "install-default" => "bootstrap" do
    puts("[plugin:install-default] Installing default plugins")

    remove_lockfile # because we want to use the release lockfile
    install_plugins("--no-verify", "--preserve", *LogStash::RakeLib::DEFAULT_PLUGINS)

    # Clean duplicates after full gem resolution
    Rake::Task["plugin:clean-duplicate-gems"].invoke
    task.reenable # Allow this task to be run again
  end

  task "remove-non-oss-plugins" do |task, _|
    puts("[plugin:remove-non-oss-plugins] Removing non-OSS plugins")

    LogStash::RakeLib::OSS_EXCLUDED_PLUGINS.each do |plugin|
      remove_plugin(plugin)
      # gem folder and spec file still stay after removing the plugin
      FileUtils.rm_r(Dir.glob("#{LogStash::Environment::BUNDLE_DIR}/**/gems/#{plugin}*"))
      FileUtils.rm_r(Dir.glob("#{LogStash::Environment::BUNDLE_DIR}/**/specifications/#{plugin}*.gemspec"))
    end
    task.reenable # Allow this task to be run again
  end

  task "trim-for-observabilitySRE" do |task, _|
    puts("[plugin:trim-for-observabilitySRE] Removing plugins not necessary for observabilitySRE")

    allow_list = (Pathname.new(__dir__).parent / "x-pack" / "distributions" / "internal" / "observabilitySRE" / "plugin-allow-list.txt").readlines.map(&:chomp)
    installed_plugins = list_plugins(expand: false)

    excess_plugins = installed_plugins - allow_list

    remove_plugin(*excess_plugins) unless excess_plugins.empty?

    task.reenable # Allow this task to be run again
  end

  task "build-fips-validation-plugin" do |task, _|
    puts("[plugin:build-fips-validation-plugin] installing fips_validation plugin")

    with_merged_env("GEM_BUILD_VERSION" => get_versions.fetch("logstash")) do
      name = "logstash-integration-fips_validation"
      path = Pathname.new(__dir__).parent / "x-pack" / "distributions" / "internal" / "observabilitySRE" / "plugin" / name

      # ensure fresh GEM_BUILD_VERSION comes from the env
      path.glob("GEM_BUILD_VERSION").each(&:unlink)

      Rake::Task["plugin:build-local-core-gem"].invoke(name, path.to_s)
    end

    task.reenable # Allow this task to be run again
  end

  task "install-fips-validation-plugin" => "build-fips-validation-plugin" do |task, _|
    puts("[plugin:install-fips-validation-plugin] installing fips_validation plugin")

    path = "build/gems"
    name = "logstash-integration-fips_validation"
    gems = Dir[File.join(path, "#{name}-*.gem")]
    abort("ERROR: #{name} gem not found in #{path}") if gems.size != 1
    puts("[plugin:install-fips-validation-plugin] Installing #{gems.first}")
    install_plugins("--no-verify", gems.first)

    task.reenable # Allow this task to be run again
  end

  task "clean-local-core-gem", [:name, :path] do |task, args|
    name = args[:name]
    path = args[:path]

    Dir[File.join(path, "#{name}*.gem")].each do |gem|
      puts("[plugin:clean-local-core-gem] Cleaning #{gem}")
      rm(gem)
    end

    task.reenable # Allow this task to be run again
  end

  task "build-local-core-gem", [:name, :path] => ["build/gems"]  do |task, args|
    name = args[:name]
    path = args[:path]

    Rake::Task["plugin:clean-local-core-gem"].invoke(name, path)

    puts("[plugin:build-local-core-gem] Building #{File.join(path, name)}.gemspec")

    gem_path = nil
    Dir.chdir(path) do
      spec = Gem::Specification.load("#{name}.gemspec")
      gem_path = Gem::Package.build(spec)
    end
    FileUtils.cp(File.join(path, gem_path), "build/gems/")

    task.reenable # Allow this task to be run again
  end

  task "install-local-core-gem", [:name, :path] do |task, args|
    name = args[:name]
    path = args[:path]

    Rake::Task["plugin:build-local-core-gem"].invoke(name, path)

    gems = Dir[File.join(path, "#{name}*.gem")]
    abort("ERROR: #{name} gem not found in #{path}") if gems.size != 1
    puts("[plugin:install-local-core-gem] Installing #{gems.first}")
    install_plugins("--no-verify", gems.first)

    task.reenable # Allow this task to be run again
  end

  # @param env [Hash]
  def with_merged_env(env)
    backup = ENV.to_hash
    ENV.replace(backup.merge(env).compact)
    yield
  ensure
    ENV.replace(backup)
  end
end # namespace "plugin"
