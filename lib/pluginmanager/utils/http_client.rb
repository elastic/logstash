# encoding: utf-8
module LogStash module PluginManager module Utils
  class HttpClient
    class RedirectionLimit < RuntimeError; end

    HTTPS_SCHEME = "https"
    REDIRECTION_LIMIT = 5

    # Proxies should be handled by the library
    # https://ruby-doc.org/stdlib-2.3.1/libdoc/net/http/rdoc/Net/HTTP.html#class-Net::HTTP-label-Proxies
    def self.start(uri)
      uri = URI(uri)
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == HTTPS_SCHEME) { |http| yield http }
    end

    # Do a HEAD request on the file to see if it exist before downloading it
    def self.remote_file_exist?(uri, redirect_count = 0)
      uri = URI(uri)

      # This is defensive programming, but in the real world we do create redirects all the time
      raise RedirectionLimit, "Too many redirection, tried #{REDIRECTION_LIMIT} times" if redirect_count >= REDIRECTION_LIMIT

      start(uri) do |http|
        return false if uri.path.empty?

        request = Net::HTTP::Head.new(uri.path)
        response = http.request(request)

        if response.code == "302"
          new_uri = response.headers["location"]
          remote_file_exist?(new_uri, redirect_count + 1)
        elsif response.code == "200"
          true
        else
          false
        end
      end
    end
  end
end end end
