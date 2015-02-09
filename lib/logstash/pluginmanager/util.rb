module LogStash::PluginManager

  # capture any $stdout from the passed block. also trap any exception in that block, in which case the trapped exception will be returned
  # @param [Proc] the code block to execute
  # @return [String, Exception] the captured $stdout string and any trapped exception or nil if none
  def self.capture_stdout
    begin
      old_stdout = $stdout
      $stdout = StringIO.new('', 'w')
      begin
        yield
      rescue => e
        return [$stdout.string, e]
      end

      [$stdout.string, nil]
    ensure
      $stdout = old_stdout
    end
  end

  # execute bundle install and capture any $stdout output. any raised exception in the process will be trapped
  # and returned. logs errors to $stdout.
  # @param options [Hash] invoke options with default values, :max_tries => 10, :clean => false, :install => false, :update => false
  # @return [String, Exception] the installation captured output and any raised exception or nil if none
  def self.invoke_bundler!(options = {})
    options = {:max_tries => 10, :clean => false, :install => false, :update => false}.merge(options)

    ENV["GEM_PATH"] = LogStash::Environment.logstash_gem_home
    ENV["BUNDLE_PATH"] = LogStash::Environment.logstash_gem_home
    ENV["BUNDLE_GEMFILE"] = LogStash::Environment::GEMFILE_PATH

    try = 0

    # capture_stdout also traps any raised exception and pass them back as the function return [output, exception]
    capture_stdout do
      loop do
        begin
          # t = $stdout; $stdout = STDOUT; require "pry"; binding.pry; $stdout = t
          Bundler.reset!
          Bundler::CLI.start(bundler_arguments(options))
          break
        rescue Bundler::VersionConflict => e
          $stderr.puts("Plugin version conflict, aborting")
          raise(e)
        rescue Bundler::GemNotFound => e
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

  # build Bundler::CLI.start arguments array from the given options hash
  # @param option [Hash] the invoke_bundler! options hash
  # @return [Array<String>] Bundler::CLI.start string arguments array
  def self.bundler_arguments(options = {})
    arguments = []

    if options[:install]
      arguments << "install"
      arguments << "--gemfile=#{LogStash::Environment::GEMFILE_PATH}"
      arguments << ["--path", LogStash::Environment::BUNDLE_DIR]
      arguments << "--without=development" unless LogStash::Environment.development?
    end

    if options[:update]
      arguments << "update"
      arguments << options[:update] if options[:update].is_a?(String)
    end

    arguments << "--clean" if options[:clean]

    arguments.flatten
  end

  # check for valid logstash plugin gem name & version or .gem file, logs errors to $stdout
  # uses Rubygems API and will remotely validated agains the current Gem.sources
  # @param plugin [String] plugin name or .gem file path
  # @param version [String] gem version requirement string
  # @return [Boolean] true if valid logstash plugin gem name & version or a .gem file
  def self.is_logstash_plugin?(plugin, version = nil)
    if is_plugin_file?(plugin)
      begin
        return is_logstash_plugin_gem_spec?(plugin_file_spec(plugin))
      rescue => e
        $stderr.puts("Error reading plugin file #{plugin}, caused by #{e.class}")
        $stderr.puts(e.message) if ENV["DEBUG"]
        return false
      end
    else
      dep = Gem::Dependency.new(plugin, version || Gem::Requirement.default)
      specs, error = Gem::SpecFetcher.fetcher.spec_for_dependency(dep)

      # depending on version requirements, multiple specs can be returned in which case
      # we will grab the one with the highest version number
      if latest = specs.map{|tuple| tuple.first}.max_by{|spec| spec.version}
        unless valid = is_logstash_plugin_gem_spec?(latest)
          $stderr.puts("#{plugin} is not a Logstash plugin")
        end
        return valid
      else
        $stderr.puts("Plugin #{plugin}" + (version ? " version #{version}" : "") + " does not exists")
        return false
      end
    end
  end

  # @param spec [Gem::Specification] plugin gem specification
  # @return [Boolean] true if this spec is for an installable logstash plugin
  def self.is_logstash_plugin_gem_spec?(spec)
    spec.metadata["logstash_plugin"] == "true"
  end

  # @param path [String] path to .gem file
  # @return [Gem::Specification] .get file gem specification
  # @raise [Exception] Gem::Package::FormatError will be raised on invalid .gem file format, might be other exceptions too
  def self.plugin_file_spec(path)
    Gem::Package.new(path).spec
  end

  # @param plugin [String] the plugin name or the local path to a .gem file
  # @return [Boolean] true if the plugin is a local .gem file
  def self.is_plugin_file?(plugin)
    (plugin =~ /\.gem$/ && File.file?(plugin))
  end

  # retrieve gem specs for all or specified name valid logstash plugins locally installed
  # @param name [String] specific plugin name to find or nil for all plungins
  # @return [Array<Gem::Specification>] all local logstash plugin gem specs
  def self.find_plugins_gem_specs(name = nil)
    specs = name ? Gem::Specification.find_all_by_name(name) : Gem::Specification.find_all
    specs.select{|spec| is_logstash_plugin_gem_spec?(spec)}
  end

  # list of all locally installed plugins specs specified in the Gemfile.
  # note that an installed plugin dependecies like codecs will not be listed, only those
  # specifically listed in the Gemfile.
  # @param gemfile [LogStash::Gemfile] the gemfile to validate against
  # @return [Array<Gem::Specification>] list of plugin names
  def self.all_installed_plugins_gem_specs(gemfile)
    # we start form the installed gemspecs so we can verify the metadata for valid logstash plugin
    # then filter out those not included in the Gemfile
    find_plugins_gem_specs.select{|spec| !!gemfile.find(spec.name)}
  end

  # @param plugin [String] plugin name
  # @param gemfile [LogStash::Gemfile] the gemfile to validate against
  # @return [Boolean] true if the plugin is an installed logstash plugin and spefificed in the Gemfile
  def self.is_installed_plugin?(plugin, gemfile)
    !!gemfile.find(plugin) && !find_plugins_gem_specs(plugin).empty?
  end



  class Util
    def self.logstash_plugin?(gem)
      gem_data = case
        when gem.is_a?(Gem::Specification)
          gem
        when (gem =~ /\.gem$/ and File.file?(gem))
          Gem::Package.new(gem).spec
        else
          Gem::Specification.find_by_name(gem)
      end

      gem_data.metadata['logstash_plugin'] == "true" ? gem_data : false
    end

    def self.download_gem(gem_name, gem_version = '')
      gem_version ||= Gem::Requirement.default

      dep = ::Gem::Dependency.new(gem_name, gem_version)
      specs_and_sources, errors = ::Gem::SpecFetcher.fetcher.spec_for_dependency dep
      if specs_and_sources.empty?
        return false
      end
      spec, source = specs_and_sources.max_by { |s,| s.version }
      path = source.download( spec, java.lang.System.getProperty("java.io.tmpdir"))
      path
    end

    def self.installed?(name)
      Gem::Specification.any? { |x| x.name == name }
    end

    def self.matching_specs(name)
      req = Gem::Requirement.default
      re = name ? /#{name}/i : //
      specs = Gem::Specification.find_all{|spec| spec.name =~ re && req =~ spec.version}
      specs.inject({}){|result, spec| result[spec.name_tuple] = spec; result}.values
    end

    def self.ask_yesno(prompt)
      while true
        $stderr.puts ("#{prompt} [y/n]: ")
        case $stdin.getc.downcase
          when 'Y', 'y', 'j', 'J', 'yes' #j for Germans (Ja)
            return true
          when /\A[nN]o?\Z/ #n or no
            break
        end
      end
    end
  end

  # This adds the "repo" element to the jar-dependencies DSL
  # allowing a gemspec to require a jar that exists in a custom
  # maven repository
  # Example:
  #   gemspec.requirements << "repo http://localhosty/repo"
  require 'maven/tools/dsl/project_gemspec'
  class Maven::Tools::DSL::ProjectGemspec
    def repo(url)
      @parent.repository(:id => url, :url => url)
    end
  end

end