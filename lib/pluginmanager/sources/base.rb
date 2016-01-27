# encoding: utf-8
require "rubygems/package"

module LogStash::PluginManager::Sources

  def self.factory(arg)
    zip_file = ::File.extname("#{arg}") == ".zip"
    if !zip_file || ( zip_file && arg.start_with?("http") )
      return HTTP.new(arg)
    end
    Local.new(arg)
  end

  class Base

    attr_reader :uri

    def initialize(uri)
      @uri = URI(uri)
    end

    def exist?
      raise "NotImplemented"
    end

    def fetch(dest="")
      raise "NotImplemented"
    end

    def version
      File.basename("#{uri}", ".zip").split("-")[1]
    end

    def to_s
      uri.to_s
    end

    def valid?
      return false if version.nil? || version.empty?
      is_zip_file? && valid_version?
    end

    def valid_version?
      LOGSTASH_VERSION == version
    end

    private

    def is_zip_file?
      ::File.extname("#{uri}") == ".zip"
    end

  end

end
