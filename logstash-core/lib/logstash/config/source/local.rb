# encoding: utf-8
require "logstash/config/source/base"
require "logstash/config/config_part"
require "logstash/config/pipeline_config"
require "logstash/util/loggable"
require "uri"

module LogStash module Config module Source
  # A locally defined configuration source
  #
  # Which can aggregate the following config streams:
  #  - settings.config_string: "input { stdin {} }"
  #  - settings.config_path: /tmp/logstash/*.conf
  #  - settings.config_path: http://localhost/myconfig.conf
  #
  #  All theses option will create a unique pipeline
  #
  class Local
    class ConfigStringLoader
      def self.read(config_string)
        [ConfigPart.new(self.name, "config_string", config_string)]
      end
    end

    class ConfigPathLoader
      include LogStash::Util::Loggable

      TEMPORARY_FILE_RE = /~$/

      def initialize(path)
        @path = ::File.expand_path(path)
      end

      def read
        config_parts = []
        encoding_issue_files = []

        get_files(@path).each do |file|
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
          fail("The following config files contains non-ascii characters but are not UTF-8 encoded #{encoding_issue_files}")
        end

        config_parts
      end

      def self.read(path)
        ConfigPathLoader.new(path).read
      end

      private
      def get_files(path)
        if ::File.directory?(@path)
          path = ::File.join(path, "*")
        end

        Dir.glob(path).sort
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
        begin
          config_string = Net::HTTP.get(uri)
          [ConfigPart.new(self.name, uri.to_s, config_string)]
        rescue Exception => e
          fail(I18n.t("logstash.runner.configuration.fetch-failed", :path => uri.to_s, :message => e.message))
        end
      end
    end

    PIPELINE_ID = :main
    HTTP_RE = /^http(s)/

    def initialize(settings)
      @settings = settings
    end

    def pipeline_configs
      config_parts = []

      config_parts << ConfigStringLoader.read(config_string) if config_string?
      config_parts << ConfigPathLoader.read(config_path) if local_config?
      config_parts << ConfigRemoteLoader.read(config_path) if remote_config?

      config_parts.flatten!

      PipelineConfig.new(self.class, PIPELINE_ID, config_parts, @settings)
    end

    def self.match?(settings)
      settings.get("config.string") || settings.get("path.config")
    end

    private
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
