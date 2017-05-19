# encoding: utf-8
require "logstash/config/source/base"
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
        [org.logstash.common.SourceWithMetadata.new("string", "config_string", config_string)]
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

        if logger.debug?
          logger.debug("Skipping the following files while reading config since they don't match the specified glob pattern", :files => get_unmatched_files)
        end

        get_matched_files.each do |file|
          next unless ::File.file?(file) # skip directory

          logger.debug("Reading config file", :config_file => file)

          if temporary_file?(file)
            logger.warn("NOT reading config file because it is a temp file", :config_file => file)
            next
          end

          config_string = ::File.read(file)

          if valid_encoding?(config_string)
            part = org.logstash.common.SourceWithMetadata.new("file", file, config_string)
            config_parts << part
          else
            encoding_issue_files << file
          end
        end

        if encoding_issue_files.any?
          raise LogStash::ConfigLoadingError, "The following config files contains non-ascii characters but are not UTF-8 encoded #{encoding_issue_files}"
        end

        if config_parts.empty?
          logger.info("No config files found in path", :path => path)
        end

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

      def get_matched_files
        Dir.glob(path).sort
      end

      def path
        if ::File.directory?(@path)
          ::File.join(@path, "*")
        else
          @path
        end
      end

      def get_unmatched_files
        # transform "/var/lib/*.conf" => /var/lib/*
        t = File.split(@path)
        all_files = Dir.glob(File.join(t.first, "*")).sort
        all_files - get_matched_files
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
            [org.logstash.common.SourceWithMetadata.new(uri.scheme, uri.to_s, response.body)]
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

    PIPELINE_ID = LogStash::SETTINGS.get("pipeline.id").to_sym
    HTTP_RE = /^http(s)?/
    INPUT_BLOCK_RE = /input *{/
    OUTPUT_BLOCK_RE = /output *{/

    def pipeline_configs

      unless mutually_exclusive(config_string?, local_config?, remote_config?)
        raise ConfigurationError.new("Settings 'config.string' and 'path.config' can't be used simultaneously.")
      end

      config_parts = if config_string?
        ConfigStringLoader.read(config_string)
      elsif local_config?
        ConfigPathLoader.read(config_path)
      elsif remote_config?
        ConfigRemoteLoader.read(config_path)
      else
        []
      end

      return if config_parts.empty?

      add_missing_default_inputs_or_outputs(config_parts) if config_string?

      [PipelineConfig.new(self.class, PIPELINE_ID, config_parts, @settings)]
    end

    def match?
      config_string? || config_path?
    end

    private
    # Make sure we have an input and at least 1 output
    # if its not the case we will add stdin and stdout
    # this is for backward compatibility reason
    def add_missing_default_inputs_or_outputs(config_parts)
      if !config_parts.any? { |part| INPUT_BLOCK_RE.match(part.text) }
        config_parts << org.logstash.common.SourceWithMetadata.new(self.class.name, "default input", LogStash::Config::Defaults.input)
      end

      # include a default stdout output if no outputs given
      if !config_parts.any? { |part| OUTPUT_BLOCK_RE.match(part.text) }
        config_parts << org.logstash.common.SourceWithMetadata.new(self.class.name, "default output", LogStash::Config::Defaults.output)
      end
    end

    def config_string
      @settings.get("config.string")
    end

    def config_string?
      !config_string.nil?
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

    def mutually_exclusive(a, b, c)
      (a ^ b ^ c) && !(a && b && c)
    end
  end
end end end
