# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "elasticsearch"
require "elasticsearch/transport/transport/http/manticore"

module LogStash class ElasticsearchClient
  include LogStash::Util::Loggable

  class Response
    # duplicated here from Elasticsearch::Transport::Transport::Response
    # to create a normalised response across different client IMPL
    attr_reader :status, :body, :headers
    def initialize(status, body, headers={})
      @status, @body, @headers = status, body, headers
      @body = body.force_encoding('UTF-8') if body.respond_to?(:force_encoding)
    end
  end

  def self.build(settings)
    new(RubyClient.new(settings, logger))
  end

  class RubyClient
    def initialize(settings, logger)
      @settings = settings
      @logger = logger
      @client_args = client_args
      @client = Elasticsearch::Client.new(@client_args)
    end

    def can_connect?
      begin
        head(SecureRandom.hex(32).prepend('_'))
      rescue Elasticsearch::Transport::Transport::Errors::BadRequest
        true
      rescue Manticore::SocketException
        false
      end
    end

    def host_settings
      @client_args[:hosts]
    end

    def delete(path)
      begin
        normalize_response(@client.perform_request('DELETE', path, {}, nil))
      rescue Exception => e
        if is_404_error?(e)
          Response.new(404, "", {})
        else
          raise e
        end
      end
    end

    def put(path, content)
      normalize_response(@client.perform_request('PUT', path, {}, content))
    end

    def head(path)
      begin
        normalize_response(@client.perform_request('HEAD', path, {}, nil))
      rescue Exception => e
        if is_404_error?(e)
          Response.new(404, "", {})
        else
          raise e
        end
      end
    end

    private

    def is_404_error?(error)
      error.class.to_s =~ /NotFound/ || error.message =~ /Not\s*Found|404/i
    end

    def normalize_response(response)
      Response.new(response.status, response.body, response.headers)
    end

    def client_args
      {
        :transport_class => Elasticsearch::Transport::Transport::HTTP::Manticore,
        :hosts => [*unpack_hosts],
        # :logger => @logger, # silence the client logging
      }
    end

    def unpack_hosts
      @settings.fetch("var.output.elasticsearch.hosts", "localhost:9200").split(',').map(&:strip)
    end
  end

  def initialize(client)
    @client = client
  end

  def delete(path)
    @client.delete(path)
  end

  def put(path, content)
    @client.put(path, content)
  end

  def head(path)
    @client.head(path)
  end

  def can_connect?
    @client.can_connect?
  end

  def host_settings
    @client.host_settings
  end
end end # class LogStash::ModulesImporter
