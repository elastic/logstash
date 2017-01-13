# encoding: utf-8
require "logstash/config/source_loader/base"
require "logstash/config/config_part"
require "net/http"

module LogStash module Config module SourceLoader
  class RemoteFile < Base
    class SourceMetadata
      def initialize(url)
        @url = url
      end

      def identifier
        @url
      end
    end

    HTTP_RE = /^http/

    def initialize(settings)
      super(settings)
      @uri = URI.parse(settings.get("path.config"))
    end

    def pipeline_configs
      begin
        [ConfigPart.new(self.class, PIPELINE_NAME, SourceMetadata.new(@uri), Net::HTTP.get(@uri))]
      rescue Exception => e
        fail(I18n.t("logstash.runner.configuration.fetch-failed", :path => uri.to_s, :message => e.message))
      end
    end

    def self.match?(settings)
      begin
        uri = URI.parse(settings.get("path.config"))
        uri.scheme =~ HTTP_RE
      rescue URI::InvalidURIError
        false
      end
    end
  end
end end end
