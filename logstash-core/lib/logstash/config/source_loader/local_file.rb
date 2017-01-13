# encoding: utf-8
require "logstash/config/source_loader/base"
require "logstash/config/config_part"
require "uri"

module LogStash module Config module SourceLoader
  class LocalFile < Base
    include LogStash::Util::Loggable

    class SourceMetadata
      def initialize(file)
        @file = file
      end

      def identifier
        @file
      end
    end

    TEMPORARY_FILE_RE = /~$/

    def initialize(settings)
      super(settings)
      @path = ::File.expand_path(settings.get("path.config"))
    end

    def pipeline_configs
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
          config_parts << ConfigPart.new(self.class, PIPELINE_NAME, SourceMetadata.new(file), config_string)
        else
          encoding_issue_files << file
        end
      end

      if encoding_issue_files.any?
        fail("The following config files contains non-ascii characters but are not UTF-8 encoded #{encoding_issue_files}")
      end

      config_parts
    end

    def self.match?(settings)
      path = settings.get("path.config")
      begin
        uri = URI.parse(path)
        uri.scheme == "file" || uri.scheme.nil?
      rescue URI::InvalidURIError
        # fallback for windows.
        # if the parsing of the file failed we assume we can reach it locally.
        # some relative path on windows arent parsed correctly (.\logstash.conf)
        path ? true : false
      end
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
end end end
