require "bundler"
require "bundler/cli"

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
  end
end

module LogStash
  module Bundler
    # Take a gem package and extract it to a specific target
    # @param [String] Gem file, this must be a path
    # @param [String, String] Return a Gem::Package and the installed path
    def self.unpack(file, path)
      require "rubygems/package"
      require "securerandom"

      # We are creating a random directory per extract,
      # if we dont do this bundler will not trigger download of the dependencies.
      # Use case is:
      # - User build his own gem with a fix
      # - User doesnt increment the version
      # - User install the same version but different code or dependencies multiple times..
      basename  = ::File.basename(file, '.gem') 
      unique = SecureRandom.hex(4)
      target_path = ::File.expand_path(::File.join(path, unique, basename))
      
      package = ::Gem::Package.new(file)
      package.extract_files(target_path)

      return [package, target_path]
    end

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

      # force Rubygems sources to our Gemfile sources
      ::Gem.sources = options[:rubygems_source] if options[:rubygems_source]

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
    # @param option [Hash] the invoke_bundler! options hash
    # @return [Array<String>] Bundler::CLI.start string arguments array
    def self.bundler_arguments(options = {})
      arguments = []

      if options[:install]
        arguments << "install"
        arguments << "--clean" if options[:clean]
      elsif options[:update]
        arguments << "update"
        arguments << options[:update]
      elsif options[:clean]
        arguments << "clean"
      end

      arguments.flatten
    end
  end
end
