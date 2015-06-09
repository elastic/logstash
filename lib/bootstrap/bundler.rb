# encoding: utf-8
module LogStash
  module Bundler
    extend self

    def patch!
      # Patch bundler to write a .lock file specific to the version of ruby.
      # This keeps MRI/JRuby/RBX from conflicting over the Gemfile.lock updates
      ::Bundler::SharedHelpers.module_exec do
        def default_lockfile
          ruby = "#{Environment.ruby_engine}-#{Environment.ruby_abi_version}"
          Pathname.new("#{default_gemfile}.#{ruby}.lock")
        end
      end

      # Patch to prevent Bundler to save a .bundle/config file in the root 
      # of the application
      ::Bundler::Settings.module_exec do
        def set_key(key, value, hash, file)
          key = key_for(key)

          unless hash[key] == value
            hash[key] = value
            hash.delete(key) if value.nil?
          end

          value
        end
      end

      # This patch makes rubygems fetch directly from the remote servers
      # the dependencies he need and might not have downloaded in a local
      # repository. This basically enabled the offline feature to work as
      # we remove the gems from the vendor directory before packacing.
      ::Bundler::Source::Rubygems.module_exec do
        def cached_gem(spec)
          cached_built_in_gem(spec)
        end
      end
    end

    def setup!(options = {})
      options = {:without => [:development]}.merge(options)
      options[:without] = Array(options[:without])

      # make sure we use our own installed bundler
      LogStash::Rubygems.patch!
      ::Gem.clear_paths
      ::Gem.paths = ENV['GEM_HOME'] = ENV['GEM_PATH'] = Environment.logstash_gem_home

      # set BUNDLE_GEMFILE ENV before requiring bundler to avoid bundler recurse and load unrelated Gemfile(s)
      ENV["BUNDLE_GEMFILE"] = Environment::GEMFILE_PATH

      require "bundler"
      LogStash::Bundler.patch!

      ::Bundler.settings[:path] = Environment::BUNDLE_DIR
      ::Bundler.settings[:without] = options[:without].join(":")
      # in the context of Bundler.setup it looks like this is useless here because Gemfile path can only be specified using
      # the ENV, see https://github.com/bundler/bundler/blob/v1.8.3/lib/bundler/shared_helpers.rb#L103
      ::Bundler.settings[:gemfile] = Environment::GEMFILE_PATH

      ::Bundler.reset!
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
                 :all => false, :package => false, :without => [:development]}.merge(options)
      options[:without] = Array(options[:without])
      options[:update] = Array(options[:update]) if options[:update]

      # make sure we use our own installed bundler
      # require "logstash/patches/rubygems" # patch rubygems before clear_paths
      LogStash::Rubygems.patch!
      ::Gem.clear_paths
      ::Gem.paths = ENV['GEM_HOME'] = ENV['GEM_PATH'] = LogStash::Environment.logstash_gem_home

      # set BUNDLE_GEMFILE ENV before requiring bundler to avoid bundler recurse and load unrelated Gemfile(s).
      # in the context of calling Bundler::CLI this is not really required since Bundler::CLI will look at
      # Bundler.settings[:gemfile] unlike Bundler.setup. For the sake of consistency and defensive/future proofing, let's keep it here.
      ENV["BUNDLE_GEMFILE"] = LogStash::Environment::GEMFILE_PATH

      require "bundler"
      require "bundler/cli"
      LogStash::Bundler.patch!

      # force Rubygems sources to our Gemfile sources
      ::Gem.sources = ::Gem::SourceList.from(options[:rubygems_source]) if options[:rubygems_source]

      ::Bundler.settings[:path] = LogStash::Environment::BUNDLE_DIR
      ::Bundler.settings[:gemfile] = LogStash::Environment::GEMFILE_PATH
      ::Bundler.settings[:without] = options[:without].join(":")

      try = 0
      # capture_stdout also traps any raised exception and pass them back as the function return [output, exception]
      output, exception = capture_stdout do
        loop do
          begin
            ::Bundler.reset!
            ::Bundler::CLI.start(bundler_arguments(options))
            break
          rescue ::Bundler::VersionConflict => e
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

    # build Bundler::CLI.start arguments array from the given options hash
    # @param option [Hash] the invoke! options hash
    # @return [Array<String>] Bundler::CLI.start string arguments array
    def bundler_arguments(options = {})
      arguments = []

      if options[:install]
        arguments << "install"
        arguments << "--clean" if options[:clean]
        if options[:local]
          arguments << "--local"
          arguments << "--no-prune" # From bundler docs: Don't remove stale gems from the cache.
        end
      elsif options[:update]
        arguments << "update"
        arguments << options[:update]
        arguments << "--local" if options[:local]
      elsif options[:clean]
        arguments << "clean"
      elsif options[:package]
        arguments << "package"
        arguments << "--all" if options[:all]
      end

      arguments.flatten
    end

   # capture any $stdout from the passed block. also trap any exception in that block, in which case the trapped exception will be returned
    # @param [Proc] the code block to execute
    # @return [String, Exception] the captured $stdout string and any trapped exception or nil if none
    def capture_stdout(&block)
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
