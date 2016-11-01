require "logstash/config/defaults"

module LogStash; module Config; class Loader
  def initialize(logger)
    @logger = logger
    @config_debug = LogStash::SETTINGS.get_value("config.debug")
  end

  def format_config(config_path, config_string)
    config_string = config_string.to_s
    if config_path
      # Append the config string.
      # This allows users to provide both -f and -e flags. The combination
      # is rare, but useful for debugging.
      loaded_config = load_config(config_path)
      if loaded_config.empty? && config_string.empty?
        # If loaded config from `-f` is empty *and* if config string is empty we raise an error
        fail(I18n.t("logstash.runner.configuration.file-not-found", :path => config_path))
      end

      # tell the user we are merging, otherwise it is very confusing
      if !loaded_config.empty? && !config_string.empty?
        @logger.info("Created final config by merging config string and config path", :path => config_path)
      end

      config_string = config_string + loaded_config
    else
      # include a default stdin input if no inputs given
      if config_string !~ /input *{/
        config_string += LogStash::Config::Defaults.input
      end
      # include a default stdout output if no outputs given
      if config_string !~ /output *{/
        config_string += LogStash::Config::Defaults.output
      end
    end
    config_string
  end

  def load_config(path)
    begin
      uri = URI.parse(path)

      case uri.scheme
      when nil then
        local_config(path)
      when /http/ then
        fetch_config(uri)
      when "file" then
        local_config(uri.path)
      else
        fail(I18n.t("logstash.runner.configuration.scheme-not-supported", :path => path))
      end
    rescue URI::InvalidURIError
      # fallback for windows.
      # if the parsing of the file failed we assume we can reach it locally.
      # some relative path on windows arent parsed correctly (.\logstash.conf)
      local_config(path)
    end
  end

  def local_config(path)
    path = ::File.expand_path(path)
    path = ::File.join(path, "*") if ::File.directory?(path)

    config = ""
    if Dir.glob(path).length == 0
      @logger.info("No config files found in path", :path => path)
      return config
    end

    encoding_issue_files = []
    Dir.glob(path).sort.each do |file|
      next unless ::File.file?(file)
      if file.match(/~$/)
        @logger.debug("NOT reading config file because it is a temp file", :config_file => file)
        next
      end
      @logger.debug("Reading config file", :config_file => file)
      cfg = ::File.read(file)
      if !cfg.ascii_only? && !cfg.valid_encoding?
        encoding_issue_files << file
      end
      config << cfg + "\n"
      if @config_debug
        @logger.debug? && @logger.debug("\nThe following is the content of a file", :config_file => file.to_s)
        @logger.debug? && @logger.debug("\n" + cfg + "\n\n")
      end
    end
    if encoding_issue_files.any?
      fail("The following config files contains non-ascii characters but are not UTF-8 encoded #{encoding_issue_files}")
    end
    if @config_debug
      @logger.debug? && @logger.debug("\nThe following is the merged configuration")
      @logger.debug? && @logger.debug("\n" + config + "\n\n")
    end
    return config
  end # def load_config

  def fetch_config(uri)
    begin
      Net::HTTP.get(uri) + "\n"
    rescue Exception => e
      fail(I18n.t("logstash.runner.configuration.fetch-failed", :path => uri.to_s, :message => e.message))
    end
  end
end end end
