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

module LogStash
  module Bundler
    extend self

    def patch!

      return if @bundler_patched
      @bundler_patched = true

      # Patch to prevent Bundler to save a .bundle/config file in the root
      # of the application
      ::Bundler::Settings.module_exec do
        def set_local(key, value)
          set_key(key, value, @local_config, nil)
        end
      end

      # In recent versions (currently 1.17.3) Bundler calls reset_paths! early during
      # Bundler::CLI.start (https://github.com/bundler/bundler/blob/v1.17.3/lib/bundler/cli.rb#L39)
      # This breaks our setting up of gemfile and bundle paths, the without group setting etc
      # We need to tone down this very aggressive resetter (https://github.com/bundler/bundler/blob/v1.17.3/lib/bundler.rb#L487-L500)
      # So we reimplement it here to only nullify the definition object, so that it can be computed
      # again if necessary with all the configuration in place.
      ::Bundler.module_exec do
        def self.reset_paths!
          @definition = nil
        end
      end

      # When preparing offline packs or generally when installing gems, bundler wants to have `.gem` files
      # cached. We ship a default set of gems that inclue all of the unpacked code. During dependency
      # resolution bundler still wants to ensure`.gem` files exist. This patch updates two paths in bundler where
      # it natively it would *fail* when a `.gem` file is not found. Instead of failing we force the cache to be
      # updated with a `.gem` file. This preserves the original patch behavior. There is still an open question of
      # *how* to potentially update the files we vendor or the way we set up bundler to avoid carrying this patch.
      # As of JRuby 9.4.13.0 rubygems (bundler) is at 3.6.3. There have been some releases and changes in bundler code
      # since then but it does not seem to have changed the way it handles gem files. Obviously carrying a patch like this
      # carries a maintenance burden so prioritizing a packaging solution may be
      ::Bundler::Source::Rubygems.module_exec do
        def fetch_gem_if_possible(spec, previous_spec = nil)
          path = if spec.remote
            fetch_gem(spec, previous_spec)
          else
            cached_gem(spec)
          end
          # BEGIN-PATCH: inject built-in gems
          path || cached_built_in_gem(spec)
          # END-PATCH
        end

        def cache(spec, custom_path = nil)
          cached_path = ::Bundler.settings[:cache_all_platforms] ? fetch_gem_if_possible(spec) : cached_gem(spec)
          # BEGIN-PATCH: inject built-in gems
          cached_path ||= cached_built_in_gem(spec)
          # END-PATCH
          raise GemNotFound, "Missing gem file '#{spec.file_name}'." unless cached_path
          return if File.dirname(cached_path) == ::Bundler.app_cache.to_s
          ::Bundler.ui.info "  * #{File.basename(cached_path)}"
          FileUtils.cp(cached_path, ::Bundler.app_cache(custom_path))
        rescue Errno::EACCES => e
          ::Bundler.ui.debug(e)
          raise InstallError, e.message
        end
      end

      #
      # BACKPORT: Fix `--prefer-local` flag (from rubygems/rubygems commits 607a3bf479, 209b93a, 23047a0)
      #
      # The original implementation of --prefer-local was too naive:
      # 1. It didn't pass prefer_local to Package objects
      # 2. It returned empty array when no local specs exist (instead of falling back to remote)
      # 3. It didn't properly handle default gems
      #
      # These patches fix:
      # - PR #7951: Fix `--prefer-local` flag (propagate to packages, add fallback logic)
      # - PR #8412: Fix `--prefer-local` not respecting default gems
      # - PR #8484: Fix `bundle install --prefer-local` sometimes installing very old versions
      #

      # Patch Source base class to add prefer_local! method
      ::Bundler::Source.class_eval do
        def prefer_local!
          # Base implementation - does nothing, subclasses override
        end
      end

      # Patch Source::Rubygems to track prefer_local state and handle default_specs properly
      # Also add support for JRuby bundled gems (gems in vendor/jruby/.../specifications/)
      ::Bundler::Source::Rubygems.class_eval do
        # Add prefer_local! method
        def prefer_local!
          @prefer_local = true
        end

        # Return specs from JRuby's bundled gem directory (specifications/, not specifications/default/)
        # These are gems that ship with JRuby but aren't "default gems" in the Ruby sense
        def jruby_bundled_specs
          @jruby_bundled_specs ||= begin
            idx = ::Bundler::Index.new
            jruby_gem_home = LogStash::Bundler.instance_variable_get(:@jruby_default_gem_dir)
            jruby_specs_dir = LogStash::Bundler.instance_variable_get(:@jruby_bundled_specs_dir)
            jruby_default_specs_dir = LogStash::Bundler.instance_variable_get(:@jruby_default_specs_dir)

            if jruby_gem_home && jruby_specs_dir && ::File.directory?(jruby_specs_dir)
              # gems_dir is where the actual gem code lives (gem_home/gems/)
              jruby_gems_dir = ::File.join(jruby_gem_home, "gems")

              # Get gemspecs from specifications/ but NOT from specifications/default/
              ::Dir[::File.join(jruby_specs_dir, "*.gemspec")].each do |path|
                # Skip if this is actually in the default directory
                next if jruby_default_specs_dir && path.start_with?(jruby_default_specs_dir)

                # gemspec_stub params: filename, base_dir, gems_dir
                # base_dir = gem home (parent of specifications/)
                # gems_dir = where gem code lives (gem_home/gems/)
                stub = ::Gem::StubSpecification.gemspec_stub(path, jruby_gem_home, jruby_gems_dir)
                # Create a Bundler::StubSpecification from the Gem::StubSpecification
                bundler_spec = ::Bundler::StubSpecification.from_stub(stub)
                # Set source to self (the Source::Rubygems instance) - required for materialization
                bundler_spec.source = self
                idx << bundler_spec
              end
            end
            idx
          end
        end

        # Override specs method to handle prefer_local for default_specs AND jruby_bundled_specs
        alias_method :original_specs, :specs

        def specs
          @specs ||= begin
            # remote_specs usually generates a way larger Index than the other
            # sources, and large_idx.merge! small_idx is way faster than
            # small_idx.merge! large_idx.
            index = @allow_remote ? remote_specs.dup : ::Bundler::Index.new
            index.merge!(cached_specs) if @allow_cached
            index.merge!(installed_specs) if @allow_local

            if @allow_local
              if @prefer_local
                # With prefer_local, merge jruby_bundled_specs and default_specs so they take precedence
                # over remote/cached/installed specs. This ensures JRuby's bundled gems are preferred.
                index.merge!(jruby_bundled_specs)
                index.merge!(default_specs)
              else
                # complete with default specs, only if not already available in the
                # index through remote, cached, or installed specs
                index.use(jruby_bundled_specs)
                index.use(default_specs)
              end
            end

            index
          end
        end
      end

      # Patch SourceList to propagate prefer_local! to all sources
      ::Bundler::SourceList.class_eval do
        def prefer_local!
          all_sources.each(&:prefer_local!)
        end
      end

      # Patch Definition to call sources.prefer_local! when prefer_local! is called
      ::Bundler::Definition.class_eval do
        alias_method :original_prefer_local!, :prefer_local!

        def prefer_local!
          @prefer_local = true
          sources.prefer_local!
        end
      end

      # Patch Package to add prefer_local support
      ::Bundler::Resolver::Package.class_eval do
        def prefer_local?
          @prefer_local
        end

        def consider_remote_versions!
          @prefer_local = false
        end
      end

      # Patch Resolver::Base to propagate prefer_local to packages and add include_remote_specs
      ::Bundler::Resolver::Base.class_eval do
        alias_method :original_base_initialize, :initialize

        def initialize(source_requirements, dependencies, base, platforms, options)
          @prefer_local_option = options[:prefer_local]
          original_base_initialize(source_requirements, dependencies, base, platforms, options)
        end

        alias_method :original_get_package, :get_package

        def get_package(name)
          package = original_get_package(name)
          # Inject prefer_local into packages since older Bundler doesn't pass it through
          if @prefer_local_option && !package.instance_variable_get(:@prefer_local)
            package.instance_variable_set(:@prefer_local, true)
          end
          package
        end

        def include_remote_specs(names)
          names.each do |name|
            get_package(name).consider_remote_versions!
          end
        end
      end

      # Patch Resolver to fix filter_remote_specs with proper fallback
      ::Bundler::Resolver.class_eval do
        # Override filter_remote_specs with the fixed version from Bundler 2.7+
        # This fixes the issue where --prefer-local would return empty specs
        # when no local gems are installed, instead of falling back to remote
        def filter_remote_specs(specs, package)
          if package.prefer_local?
            local_specs = specs.select {|s| s.is_a?(::Bundler::StubSpecification) }

            if local_specs.empty?
              # BACKPORT FIX: If no local specs exist, fall back to remote specs
              # instead of returning empty array
              package.consider_remote_versions!
              specs
            else
              local_specs
            end
          else
            specs
          end
        end
      end

      # Patch Source::Rubygems#install to skip installation for default gems and JRuby bundled gems
      # The original condition `spec.default_gem? && !cached_built_in_gem(...)` has a side effect:
      # cached_built_in_gem fetches from remote if not in cache. For default gems and JRuby bundled gems,
      # we should skip installation entirely without needing a cached .gem file.
      ::Bundler::Source::Rubygems.class_eval do
        alias_method :original_rubygems_install, :install

        def install(spec, options = {})
          # For default gems, skip installation entirely - they're already available
          if spec.default_gem?
            print_using_message "Using #{version_message(spec, options[:previous_spec])}"
            return nil
          end

          # For JRuby bundled gems, also skip installation - they're already available
          # Check if this exact gem (name + version) exists in JRuby's bundled gems
          jruby_specs_dir = LogStash::Bundler.instance_variable_get(:@jruby_bundled_specs_dir)
          if jruby_specs_dir && ::File.directory?(jruby_specs_dir)
            jruby_gemspec_path = ::File.join(jruby_specs_dir, "#{spec.name}-#{spec.version}.gemspec")
            if ::File.exist?(jruby_gemspec_path)
              print_using_message "Using #{version_message(spec, options[:previous_spec])}"
              return nil
            end
          end

          original_rubygems_install(spec, options)
        end
      end
    end


    # Capture JRuby's default gem directory before paths are changed
    # This is needed so that default gems (like json) can be found with --prefer-local
    def preserve_jruby_default_gems_path
      return @jruby_default_gem_dir if defined?(@jruby_default_gem_dir)

      # The Gradle/JRuby setup already changes Gem.default_dir to a temp path before
      # this code runs, so we need to construct the actual JRuby path from LOGSTASH_HOME
      logstash_home = ENV["LOGSTASH_HOME"] || ::File.expand_path("../../..", __FILE__)
      jruby_gems_dir = ::File.join(logstash_home, "vendor", "jruby", "lib", "ruby", "gems", "shared")
      jruby_default_specs = ::File.join(jruby_gems_dir, "specifications", "default")
      jruby_bundled_specs = ::File.join(jruby_gems_dir, "specifications")

      if ::File.directory?(jruby_default_specs)
        @jruby_default_gem_dir = jruby_gems_dir
        @jruby_default_specs_dir = jruby_default_specs
        @jruby_bundled_specs_dir = jruby_bundled_specs
      else
        # Fall back to Gem.default_dir if vendor/jruby doesn't exist
        @jruby_default_gem_dir = ::Gem.default_dir
        @jruby_default_specs_dir = ::Gem.default_specifications_dir
        @jruby_bundled_specs_dir = nil
      end

      @jruby_default_gem_dir
    end

    # Patch Gem::Specification.default_stubs to also look in JRuby's original specs directories
    # This is needed because Gem.default_specifications_dir only returns a single path,
    # and after Gem.paths = ENV it points to Logstash's gem home, not JRuby's installation
    # We include BOTH:
    # - specifications/default/ (true default gems)
    # - specifications/ (JRuby bundled gems like rexml, rake, net-imap, etc.)
    def patch_default_stubs!
      return if @default_stubs_patched || !defined?(@jruby_default_specs_dir) || @jruby_default_specs_dir.nil?
      @default_stubs_patched = true

      jruby_default_specs_dir = @jruby_default_specs_dir
      jruby_bundled_specs_dir = @jruby_bundled_specs_dir
      jruby_gem_home = @jruby_default_gem_dir

      ::Gem::Specification.singleton_class.class_eval do
        alias_method :original_default_stubs, :default_stubs

        define_method(:default_stubs) do |pattern = "*.gemspec"|
          # Get stubs from the current default_specifications_dir
          stubs = original_default_stubs(pattern)

          # Also look in JRuby's original default specs directory (specifications/default/)
          if jruby_default_specs_dir && ::File.directory?(jruby_default_specs_dir) && jruby_default_specs_dir != ::Gem.default_specifications_dir
            ::Dir[::File.join(jruby_default_specs_dir, pattern)].each do |path|
              # Use default_gemspec_stub to mark these as default gems (default_gem = true)
              stub = ::Gem::StubSpecification.default_gemspec_stub(path, jruby_default_specs_dir, jruby_default_specs_dir)
              stubs << stub unless stubs.any? { |s| s.name == stub.name && s.version == stub.version }
            end
          end

          # Also include JRuby's bundled gems (specifications/, excluding specifications/default/)
          # These are gems like rexml, rake, net-imap that ship with JRuby but aren't "default gems"
          # We treat them as default gems here so they're available via Bundler's add_default_gems_to
          if jruby_bundled_specs_dir && jruby_gem_home && ::File.directory?(jruby_bundled_specs_dir)
            jruby_gems_dir = ::File.join(jruby_gem_home, "gems")
            ::Dir[::File.join(jruby_bundled_specs_dir, pattern)].each do |path|
              # Skip if this is in the default directory (already handled above)
              next if jruby_default_specs_dir && path.start_with?(jruby_default_specs_dir)

              # Use gemspec_stub (not default_gemspec_stub) with correct base_dir and gems_dir
              stub = ::Gem::StubSpecification.gemspec_stub(path, jruby_gem_home, jruby_gems_dir)
              stubs << stub unless stubs.any? { |s| s.name == stub.name && s.version == stub.version }
            end
          end

          stubs
        end
      end
    end

    # prepare bundler's environment variables, but do not invoke ::Bundler::setup
    def prepare(options = {})
      options = {:without => [:development]}.merge(options)
      options[:without] = Array(options[:without])

      # Capture JRuby default gems path BEFORE clearing
      jruby_gem_dir = preserve_jruby_default_gems_path

      ::Gem.clear_paths
      # Include both Logstash gem home AND JRuby's default gem directory in GEM_PATH
      # This ensures default gems can be discovered by Gem::Specification.default_stubs
      gem_path = [Environment.logstash_gem_home, jruby_gem_dir].compact.uniq.join(::File::PATH_SEPARATOR)
      ENV['GEM_HOME'] = Environment.logstash_gem_home
      ENV['GEM_PATH'] = gem_path
      ::Gem.paths = ENV

      # Patch default_stubs to also look in JRuby's original location
      patch_default_stubs!

      # set BUNDLE_GEMFILE ENV before requiring bundler to avoid bundler recurse and load unrelated Gemfile(s)
      ENV["BUNDLE_GEMFILE"] = Environment::GEMFILE_PATH

      require "bundler"
      LogStash::Bundler.patch!

      ::Bundler.settings.set_local(:path, Environment::BUNDLE_DIR)
      ::Bundler.settings.set_local(:without, options[:without])
      # in the context of Bundler.setup it looks like this is useless here because Gemfile path can only be specified using
      # the ENV, see https://github.com/bundler/bundler/blob/v1.8.3/lib/bundler/shared_helpers.rb#L103
      ::Bundler.settings.set_local(:gemfile, Environment::GEMFILE_PATH)
      ::Bundler.settings.set_local(:frozen, true) unless options[:allow_gemfile_changes]
      ::Bundler.reset!
    end

    # After +Bundler.setup+ call, all +load+ or +require+ of the gems would be allowed only if they are part of
    # the Gemfile or Ruby's standard library
    # To install a new plugin which is not part of Gemfile, DO NOT call setup!
    def setup!(options = {})
      prepare(options)
      ::Bundler.setup
    end

    # execute bundle install and capture any $stdout output. any raised exception in the process will be trapped
    # and returned. logs errors to $stdout.
    # @param [Hash] options invoke options with default values, :max_tries => 10, :clean => false, :install => false, :update => false
    # @option options [Boolean] :max_tries The number of times bundler is going to try the installation before failing (default: 10)
    # @option options [Boolean] :clean It cleans the unused gems (default: false)
    # @option options [Boolean] :install Run the installation of a set of gems defined in a Gemfile (default: false)
    # @option options [Boolean, String, Array] :update Update the current environment, must be either false or a String or an Array of String (default: false)
    # @option options [Boolean] :local Do not attempt to fetch gems remotely and use the gem cache instead (default: false)
    # @option options [Boolean] :package Locks and then caches all dependencies to be reused later on (default: false)
    # @option options [Boolean] :all It packages dependencies defined with :git or :path (default: false)
    # @option options [Array] :without  Exclude gems that are part of the specified named group (default: [:development])
    # @return [String, Exception] the installation captured output and any raised exception or nil if none
    def invoke!(options = {})
      options = {:max_tries => 10, :clean => false, :install => false, :update => false, :local => false,
                 :jobs => 12, :all => false, :package => false, :without => [:development]}.merge(options)
      options[:without] = Array(options[:without])
      options[:update] = Array(options[:update]) if options[:update]

      # Capture JRuby default gems path BEFORE clearing
      jruby_gem_dir = preserve_jruby_default_gems_path

      ::Gem.clear_paths
      # Include both Logstash gem home AND JRuby's default gem directory in GEM_PATH
      # This ensures default gems can be discovered by Gem::Specification.default_stubs
      gem_path = [LogStash::Environment.logstash_gem_home, jruby_gem_dir].compact.uniq.join(::File::PATH_SEPARATOR)
      ENV['GEM_HOME'] = LogStash::Environment.logstash_gem_home
      ENV['GEM_PATH'] = gem_path
      ::Gem.paths = ENV

      # Patch default_stubs to also look in JRuby's original location
      patch_default_stubs!

      # set BUNDLE_GEMFILE ENV before requiring bundler to avoid bundler recurse and load unrelated Gemfile(s).
      # in the context of calling Bundler::CLI this is not really required since Bundler::CLI will look at
      # Bundler.settings[:gemfile] unlike Bundler.setup. For the sake of consistency and defensive/future proofing, let's keep it here.
      ENV["BUNDLE_GEMFILE"] = LogStash::Environment::GEMFILE_PATH

      require "bundler"
      require "bundler/cli"

      require "fileutils"
      # create Gemfile from template iff it does not exist
      unless ::File.exist?(Environment::GEMFILE_PATH)
        FileUtils.copy(
          ::File.join(Environment::LOGSTASH_HOME, "Gemfile.template"), Environment::GEMFILE_PATH
        )
      end
      # create Gemfile.jruby-1.9.lock from template iff a template exists it itself does not exist
      lock_template = ::File.join(ENV["LOGSTASH_HOME"], "Gemfile.jruby-3.1.lock.release")
      if ::File.exist?(lock_template) && !::File.exist?(Environment::LOCKFILE)
        FileUtils.copy(lock_template, Environment::LOCKFILE)
      end

      LogStash::Bundler.patch!

      # force Rubygems sources to our Gemfile sources
      ::Gem.sources = ::Gem::SourceList.from(options[:rubygems_source]) if options[:rubygems_source]

      ::Bundler.settings.set_local(:path, LogStash::Environment::BUNDLE_DIR)
      ::Bundler.settings.set_local(:gemfile, LogStash::Environment::GEMFILE_PATH)
      ::Bundler.settings.set_local(:without, options[:without])
      ::Bundler.settings.set_local(:force, options[:force])

      # This env setting avoids the warning given when bundler is run as root, as is required
      # to update plugins when logstash is run as a service
      # Note: Using `ENV`s here because ::Bundler.settings.set_local or `bundle config`
      # is not being respected with `Bundler::CLI.start`?
      # (set_global *does*, but that seems too drastic a change)
      with_env({"BUNDLE_PATH" => LogStash::Environment::BUNDLE_DIR,
                "BUNDLE_GEMFILE" => LogStash::Environment::GEMFILE_PATH,
                "BUNDLE_SILENCE_ROOT_WARNING" => "true",
                "BUNDLE_WITHOUT" => options[:without].join(":")}) do
        if !debug?
          # Will deal with transient network errors
          execute_bundler_with_retry(options)
        else
          options[:verbose] = true
          execute_bundler(options)
          ""
        end
      end
    end

    def execute_bundler_with_retry(options)
      try = 0
      # capture_stdout also traps any raised exception and pass them back as the function return [output, exception]
      output, exception = capture_stdout do
        loop do
          begin
            execute_bundler(options)
            break
          rescue ::Bundler::SolveFailure => e
            $stderr.puts("Plugin version conflict, aborting")
            raise(e)
          rescue ::Bundler::GemNotFound => e
            $stderr.puts("Plugin not found, aborting")
            raise(e)
          rescue => e
            if try >= options[:max_tries]
              $stderr.puts("Too many retries, aborting, caused by #{e.class}")
              $stderr.puts(e.message) if ENV["DEBUG"]
              raise(e)
            end

            try += 1
            $stderr.puts("Error #{e.class}, retrying #{try}/#{options[:max_tries]}")
            $stderr.puts(e.message)
            sleep(0.5)
          end
        end
      end
      raise exception if exception

      return output
    end

    def execute_bundler(options)
      ::Bundler.reset!
      ::Bundler::CLI.start(bundler_arguments(options))
    end

    def specific_platforms(platforms = ::Gem.platforms)
      platforms.find_all {|plat| plat.is_a?(::Gem::Platform) && plat.os == 'java' && !plat.cpu.nil?}
    end

    def genericize_platform
      output = LogStash::Bundler.invoke!({:add_platform => 'java'})
      specific_platforms.each do |platform|
        output << LogStash::Bundler.invoke!({:remove_platform => platform.to_s})
      end
      output
    end

    def debug?
      ENV["DEBUG"]
    end

    # @param plugin_names [Array] logstash plugin names that are going to update
    # @return [Array] gem names that plugins depend on, including logstash plugins
    def expand_logstash_mixin_dependencies(plugin_names); require 'set'
      plugin_names = Array(plugin_names) if plugin_names.is_a?(String)

      # get gem names in Gemfile.lock. If file doesn't exist, it will be generated
      lockfile_gems = ::Bundler::definition.specs.to_a.map { |stub_spec| stub_spec.name }.to_set

      # get the array of dependencies which are eligible to update. Bundler unlock these gems in update process
      # exclude the gems which are not in lock file. They should not be part of unlock gems.
      # The core libs, logstash-core logstash-core-plugin-api, are not expected to update when user do plugins update
      # constraining the transitive dependency updates to only those Logstash maintain
      unlock_libs = plugin_names.flat_map { |plugin_name| fetch_plugin_dependencies(plugin_name) }
                                .uniq
                                .select { |lib_name| lockfile_gems.include?(lib_name) }
                                .select { |lib_name| lib_name.start_with?("logstash-mixin-") }

      unlock_libs + plugin_names
    end

    # get all dependencies of a single plugin, considering all versions >= current
    # @param plugin_name [String] logstash plugin name
    # @return [Array] gem names that plugin depends on
    def fetch_plugin_dependencies(plugin_name)
      old_spec = ::Gem::Specification.find_all_by_name(plugin_name).last
      require_version = old_spec ? ">= #{old_spec.version}" : nil
      dep = ::Gem::Dependency.new(plugin_name, require_version)
      new_specs, errors = ::Gem::SpecFetcher.fetcher.spec_for_dependency(dep)

      raise(errors.first.error) if errors.length > 0

      new_specs.map { |spec, source| spec }
               .flat_map(&:dependencies)
               .select {|spec| spec.type == :runtime }
               .map(&:name)
               .uniq
    end

    # build Bundler::CLI.start arguments array from the given options hash
    # @param option [Hash] the invoke! options hash
    # @return [Array<String>] Bundler::CLI.start string arguments array
    def bundler_arguments(options = {})
      arguments = []
      if options[:install]
        arguments << "install"
        arguments << "--prefer-local"
        arguments << "--clean" if options[:clean]
        if options[:local]
          arguments << "--local"
          arguments << "--no-prune" # From bundler docs: Don't remove stale gems from the cache.
        end
        if options[:force]
          arguments << "--redownload"
        end
      elsif options[:update]
        arguments << "update"
        arguments << expand_logstash_mixin_dependencies(options[:update])
        arguments << "--#{options[:level] || 'minor'}"
        arguments << "--local" if options[:local]
        arguments << "--conservative" if options[:conservative]
      elsif options[:clean]
        arguments << "clean"
      elsif options[:package]
        arguments << "package"
        arguments << "--all" if options[:all]
      elsif options[:add_platform]
        arguments << "lock"
        arguments << "--add_platform"
        arguments << options[:add_platform]
      elsif options[:remove_platform]
        arguments << "lock"
        arguments << "--remove_platform"
        arguments << options[:remove_platform]
      end

      arguments << "--verbose" if options[:verbose]
      arguments.flatten
    end

    def with_env(modifications)
      backup_env = ENV.to_hash
      ENV.replace(backup_env.merge(modifications))

      yield
    ensure
      ENV.replace(backup_env)
    end

    # capture any $stdout from the passed block. also trap any exception in that block, in which case the trapped exception will be returned
    # @param [Proc] the code block to execute
    # @return [String, Exception] the captured $stdout string and any trapped exception or nil if none
    def capture_stdout(&block); require 'stringio'
      old_stdout = $stdout
      $stdout = StringIO.new("", "w")
      begin
        block.call
      rescue => e
        return [$stdout.string, e]
      end

      [$stdout.string, nil]
    ensure
      $stdout = old_stdout
    end
  end
end
