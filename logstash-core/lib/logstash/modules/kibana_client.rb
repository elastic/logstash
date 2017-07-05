# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "logstash/json"
require "manticore/client"

module LogStash module Modules class KibanaClient
  include LogStash::Util::Loggable

  class Response
    # to create a custom response with body as an Object (Hash or Array)
    attr_reader :status, :body, :headers
    def initialize(status, body, headers={})
      @status, @body, @headers = status, body, headers
      @body = body.is_a?(String) ? LogStash::Json.load(body) : body
    end

    def succeeded?
      @status >= 200 && @status < 300
    end

    def failed?
      !succeeded?
    end
  end

  attr_reader :version

  def initialize(settings)
    @settings = settings
    @client = Manticore::Client.new(request_timeout: 5, connect_timeout: 5, socket_timeout: 5, pool_max: 10, pool_max_per_route: 2)
    @host = @settings.fetch("var.kibana.host", "localhost:5601")
    @scheme = @settings.fetch("var.kibana.scheme", "http")
    @http_options = {:headers => {'Content-Type' => 'application/json'}}
    # e.g. {"name":"Elastics-MacBook-Pro.local","version":{"number":"6.0.0-alpha3","build_hash":"41e69","build_number":15613,"build_snapshot":true}..}
    @version = "0.0.0"
    response = get("api/status")
    if response.succeeded?
      status = response.body
      if status["version"].is_a?(Hash)
        @version = status["version"]["number"]
        if status["version"]["build_snapshot"]
          @version.concat("-SNAPSHOT")
        end
      end
    end
    @http_options[:headers]['kbn-version'] = @version
  end

  def version_parts
    @version.split(/\.|\-/)
  end

  def host_settings
    "[\"#{@host}\"]"
  end

  def get(relative_path)
    # e.g. api/kibana/settings
    safely(:get, relative_path, @http_options)
  end

  # content will be converted to a json string
  def post(relative_path, content, headers = nil)

    body = content.is_a?(String) ? content : LogStash::Json.dump(content)
    options = {:body => body}.merge(headers || @http_options)
    safely(:post, relative_path, options)
  end

  def head(relative_path)
    safely(:head, relative_path)
  end

  def can_connect?
    head("api/status").succeeded?
  end

  private

  def safely(method_sym, relative_path, options = {})
    begin
      resp = @client.http(method_sym, full_url(relative_path), options).call
      Response.new(resp.code, resp.body, resp.headers)
    rescue Manticore::ManticoreException => e
      body = {"statusCode" => 0, "error" => e.message}
      Response.new(0, body, {})
    end
  end

  def full_url(relative)
    "#{@scheme}://#{@host}/#{relative}"
  end
end end end
