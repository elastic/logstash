# encoding: utf-8
require "rubygems/package"
require "pluginmanager/sources/base"
require "net/http"

module LogStash::PluginManager::Sources

  class HTTP < Base

    attr_reader :uri, :fallback, :header_options

    ##
    # Fallback URL used by default when installing packs given
    # by name, if you require to install a pack from a custom URL
    # you will need to pass the full URL.
    ##
    ROOT_URI = "https://download.elastic.co".freeze

    ##
    # User agent string used to identify the requester is a
    # LogStash agent
    ##
    USER_AGENT = "Logstash/#{LOGSTASH_VERSION}".freeze

    def initialize(uri)
      @fallback = !uri.start_with?("http")
      if fallback
        @uri = super(fallback_uri(uri))
      else
        @uri = super(uri)
      end
      @header_options = {'User-Agent' => USER_AGENT}
    end

    def fallback_uri(uri)
      "#{ROOT_URI}/#{uri}.zip"
    end

    def valid?
      valid_format = super
      fallback ? valid_format : valid_format && exist?
    end

    def exist?
      response = Net::HTTP.start(*http_start_args(uri)) do |http|
        http.head(uri.request_uri, header_options)
      end
      response.kind_of?(Net::HTTPSuccess)
    rescue
      false
    end

    def fetch(dest="")
      path   = File.join(dest, File.basename(uri.path))
      status = nil
      Net::HTTP.start(*http_start_args(uri)) do |http|
        response = http.get(uri.request_uri, header_options)
        status   = response.code
        break unless status == "200"
        write_to_file(path, response.body)
      end
      [path, status]
    end

    private
    def write_to_file(path, data)
      File.open(path, "w") do |file|
        file.write(data)
      end
    end

    def http_start_args(uri)
      options = { :use_ssl => uri.scheme == "https" }
      [uri.host, uri.port, nil, nil, nil, nil, options]
    end
  end
end
