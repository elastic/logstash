# encoding: utf-8
require "logstash/config/source/base"
require "logstash/config/config_part"
require "logstash/config/pipeline_config"
require "logstash/util/loggable"
require "logstash/errors"
require "uri"

module LogStash module Config module Source
  # A locally defined configuration source
  #
  # Which can aggregate the following config options:
  #  - settings.config_string: "input { stdin {} }"
  #  - settings.config_path: /tmp/logstash/*.conf
  #  - settings.config_path: http://localhost/myconfig.conf
  #
  #  All theses option will create a unique pipeline, generated parts will be
  #  sorted alphabetically. Se `PipelineConfig` class for the sorting algorithm.
  #
  class Local < Base
    class ConfigStringLoader
      def self.read(config_string)
        [ConfigPart.new(self.name, "config_string", config_string)]
      end
    end

    class ConfigPathLoader
      include LogStash::Util::Loggable

      TEMPORARY_FILE_RE = /~$/
      LOCAL_FILE_URI = /^file:\/\//i

      def initialize(path)
        @path = normalize_path(path)
      end

      def read
        config_parts = []
        encoding_issue_files = []

        get_files.each do |file|
          next unless ::File.file?(file) # skip directory

          logger.debug("Reading config file", :config_file => file)

          if temporary_file?(file)
            logger.debug("NOT reading config file because it is a temp file", :config_file => file)
            next
          end

          config_string = ::File.read(file)

          if valid_encoding?(config_string)
            config_parts << ConfigPart.new(self.class.name, file, config_string)
          else
            encoding_issue_files << file
          end
        end

        if encoding_issue_files.any?
          raise LogStash::ConfigLoadingError, "The following config files contains non-ascii characters but are not UTF-8 encoded #{encoding_issue_files}"
        end

        raise LogStash::ConfigLoadingError, "Cannot load configuration for path: #{path}" if config_parts.empty?
        config_parts
      end

      def self.read(path)
        ConfigPathLoader.new(path).read
      end

      private
      def normalize_path(path)
        path.gsub!(LOCAL_FILE_URI, "")
        ::File.expand_path(path)
      end

      def get_files
        Dir.glob(path).sort
      end

      def path
        if ::File.directory?(@path)
          ::File.join(@path, "*")
        else
          @path
        end
      end

      def valid_encoding?(content)
        content.ascii_only? && content.valid_encoding?
      end

      def temporary_file?(filepath)
        filepath.match(TEMPORARY_FILE_RE)
      end
    end

    class ConfigRemoteLoader
      def self.read(uri)
        uri = URI.parse(uri)

        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == "https") do |http|
          request = Net::HTTP::Get.new(uri.path)
          response = http.request(request)

          # since we have fetching config we wont follow any redirection.
          case response.code.to_i
          when 200
            [ConfigPart.new(self.name, uri.to_s, response.body)]
          when 302
            raise LogStash::ConfigLoadingError, I18n.t("logstash.runner.configuration.fetch-failed", :path => uri.to_s, :message => "We don't follow redirection for remote configuration")
          when 404
            raise LogStash::ConfigLoadingError, I18n.t("logstash.runner.configuration.fetch-failed", :path => uri.to_s, :message => "File not found")
          when 403
            raise LogStash::ConfigLoadingError, I18n.t("logstash.runner.configuration.fetch-failed", :path => uri.to_s, :message => "Permission denied")
          when 500
            raise LogStash::ConfigLoadingError, I18n.t("logstash.runner.configuration.fetch-failed", :path => uri.to_s, :message => "500 error on remote host")
          else
            raise LogStash::ConfigLoadingError, I18n.t("logstash.runner.configuration.fetch-failed", :path => uri.to_s, :message => "code: #{response.code}, message: #{response.class.to_s}")
          end
        end
      end
    end

    PIPELINE_ID = :main
    HTTP_RE = /^http(s)?/
    INPUT_BLOCK_RE = /input *{/
    OUTPUT_BLOCK_RE = /output *{/

    def initialize(settings)
      super(settings)
    end

    def pipeline_configs
      config_parts = []

      config_parts << ConfigStringLoader.read(config_string) if config_string?
      config_parts << ConfigPathLoader.read(config_path) if local_config?
      config_parts << ConfigRemoteLoader.read(config_path) if remote_config?

      config_parts.flatten!

      add_missing_default_inputs_or_outputs(config_parts)

      PipelineConfig.new(self.class, PIPELINE_ID, config_parts, @settings)
    end

    def self.match?(settings)
      settings.get("config.string") || settings.get("path.config")
    end

    private
    # Make sure we have an input and at least 1 output
    # if its not the case we will add stdin and stdout
    # this is for backward compatibility reason
    def add_missing_default_inputs_or_outputs(config_parts)
      if !config_parts.any? { |part| INPUT_BLOCK_RE.match(part.config_string) }
        config_parts << LogStash::Config::ConfigPart.new(self.class.name, "default input", LogStash::Config::Defaults.input)
      end

      # include a default stdout output if no outputs given
      if !config_parts.any? { |part| OUTPUT_BLOCK_RE.match(part.config_string) }
        config_parts << LogStash::Config::ConfigPart.new(self.class.name, "default output", LogStash::Config::Defaults.output)
      end
    end

    def config_string
      @settings.get("config.string")
    end

    def config_string?
      !config_string.nil? && !config_string.empty?
    end

    def config_path
      @settings.get("path.config")
    end

    def config_path?
      !config_path.nil? && !config_path.empty?
    end

    def local_config?
      return false unless config_path?

      begin
        uri = URI.parse(config_path)
        uri.scheme == "file" || uri.scheme.nil?
      rescue URI::InvalidURIError
        # fallback for windows.
        # if the parsing of the file failed we assume we can reach it locally.
        # some relative path on windows arent parsed correctly (.\logstash.conf)
        true
      end
    end

    def remote_config?
      return false unless config_path?

      begin
        uri = URI.parse(config_path)
        uri.scheme =~ HTTP_RE
      rescue URI::InvalidURIError
        false
      end
    end
  end
end end end
