require "logstash/config/defaults"

module LogStash; module Config; class Loader
  attr_accessor :debug_config

  def initialize(logger, debug_config=false)
    @logger = logger
    @debug_config = debug_config
  end

  def format_config(config_path, config_string)
    config_string = config_string.to_s
    if config_path
      # Append the config string.
      # This allows users to provide both -f and -e flags. The combination
      # is rare, but useful for debugging.
      config_string = config_string + load_config(config_path)
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
        fail(I18n.t("logstash.agent.configuration.scheme-not-supported", :path => path))
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

    if Dir.glob(path).length == 0
      fail(I18n.t("logstash.agent.configuration.file-not-found", :path => path))
    end

    config = ""
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
      if @debug_config
        @logger.debug? && @logger.debug("\nThe following is the content of a file", :config_file => file.to_s)
        @logger.debug? && @logger.debug("\n" + cfg + "\n\n")
      end
    end
    if encoding_issue_files.any?
      fail("The following config files contains non-ascii characters but are not UTF-8 encoded #{encoding_issue_files}")
    end
    if @debug_config
      @logger.debug? && @logger.debug("\nThe following is the merged configuration")
      @logger.debug? && @logger.debug("\n" + config + "\n\n")
    end
    return config
  end # def load_config

  def fetch_config(uri)
    begin
      Net::HTTP.get(uri) + "\n"
    rescue Exception => e
      fail(I18n.t("logstash.agent.configuration.fetch-failed", :path => uri.to_s, :message => e.message))
    end
  end
end end end
