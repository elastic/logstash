require "bundler"
require "bundler/cli"
require 'fileutils'
require 'yaml'

module Bundler
  # Patch bundler to write a .lock file specific to the version of ruby.
  # This keeps MRI/JRuby/RBX from conflicting over the Gemfile.lock updates
  module SharedHelpers
    def default_lockfile
      ruby = "#{LogStash::Environment.ruby_engine}-#{LogStash::Environment.ruby_abi_version}"
      Pathname.new("#{default_gemfile}.#{ruby}.lock")
    end
  end

  # Add the Bundler.reset! method which has been added in master but is not in 1.7.9.
  class << self
    unless self.method_defined?("reset!")
      def reset!
        @definition = nil
      end
    end

    def reset_settings
      # reset!
      # clear_gemspec_cache

      # remove_instance_variable(:@setup) if defined?(@setup)
      # remove_instance_variable(:@locked_gems) if defined?(@locked_gems)
      # remove_instance_variable(:@load) if defined?(@load)
      remove_instance_variable(:@settings) if defined?(@settings)
    end
  end
end

module LogStash
  module Bundler

    # capture any $stdout from the passed block. also trap any exception in that block, in which case the trapped exception will be returned
    # @param [Proc] the code block to execute
    # @return [String, Exception] the captured $stdout string and any trapped exception or nil if none
    def self.capture_stdout(&block)
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

    # execute bundle install and capture any $stdout output. any raised exception in the process will be trapped
    # and returned. logs errors to $stdout.
    # @param options [Hash] invoke options with default values, :max_tries => 10, :clean => false, :install => false, :update => false
    # @param   options[:update] must be either false or a String or an Array of String
    # @return [String, Exception] the installation captured output and any raised exception or nil if none
    def self.invoke_bundler!(options = {})
      options = {:max_tries => 10, :clean => false, :install => false, :update => false, :without => [:development]}.merge(options)
      options[:without] = Array(options[:without])
      options[:update] = Array(options[:update]) if options[:update]

      ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
      ENV["BUNDLE_PATH"] = LogStash::Environment::BUNDLE_DIR
      ENV["BUNDLE_GEMFILE"] = LogStash::Environment::GEMFILE_PATH
      ENV["BUNDLE_WITHOUT"] = options[:without].join(":")

      # Update the `.bundler/config` to contains at least the BUNDLE_PATH
      # This is necessary because `bundle clean` doesnt obey to ENV['BUNDLE_PATH']
      update_bundler_config({ "BUNDLE_PATH" => LogStash::Environment::BUNDLE_DIR })

      try = 0

      # capture_stdout also traps any raised exception and pass them back as the function return [output, exception]
      capture_stdout do
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
            $stderr.puts(e.message) if ENV["DEBUG"]
            sleep(0.5)
          end
        end
      end
    end

    def self.update_bundler_config(options)
      bundle_config_path = ::File.join(LogStash::Environment::LOGSTASH_HOME, '.bundle')
      config_file = ::File.join(bundle_config_path, 'config')

      if ::File.exist?(config_file)
        content = YAML.load_file(config_file)
      else
        FileUtils.mkdir_p(bundle_config_path)
        content = {}
      end

      content.merge!(options)
      ::File.open(config_file, 'w') { |f| f.write(content.to_yaml) }
    end

    # build Bundler::CLI.start arguments array from the given options hash
    # @param option [Hash] the invoke_bundler! options hash
    # @return [Array<String>] Bundler::CLI.start string arguments array
    def self.bundler_arguments(options = {})
      arguments = []

      if options[:install]
        arguments << "install"
        arguments << "--gemfile=#{LogStash::Environment::GEMFILE_PATH}"
        arguments << ["--path", LogStash::Environment::BUNDLE_DIR]
        # note that generating "--without=" when options[:without] is empty is intended
        arguments << "--without=#{options[:without].join(' ')}"
      end

      if options[:update]
        arguments << "update"
        arguments << options[:update]
      end

      arguments << "--clean" if options[:clean]

      arguments.flatten
    end
  end
end
