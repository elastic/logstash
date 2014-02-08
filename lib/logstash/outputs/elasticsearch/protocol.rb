require "logstash/outputs/elasticsearch"
require "cabin"

module LogStash::Outputs::Elasticsearch
  module Protocols
    class Base
      private
      def initialize(options={})
        # host(s), port, cluster
        @logger = Cabin::Channel.get
      end

      def client
        return @client if @client
        @client = build_client(@options)
        return @client
      end # def client


      def template_install(name, template, force=false)
        if template_exists?(name, template) && !force
          @logger.debug("Found existing Elasticsearch template. Skipping template management", :name => name)
          return
        end
        # TODO(sissel): ???
      end

      # Do a bulk request with the given actions.
      #
      # 'actions' is expected to be an array of bulk requests as string json
      # values.
      #
      # Each 'action' becomes a single line in the bulk api call. For more
      # details on the format of each.
      def bulk(actions)
        raise NotImplemented, "You must implement this yourself"
        # bulk([
        # '{ "index" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }',
        # '{ "field1" : "value1" }'
        #])
      end

      public(:initialize)
    end

    class HTTPClient < Base
      private

      DEFAULT_OPTIONS = {
        :port => 9200
      }

      def initialize(options={})
        super
        require "elasticsearch" # gem 'elasticsearch-ruby'
        @options = DEFAULT_OPTIONS.merge(options)
        @client = client
      end

      def build_client(options)
        client = Elasticsearch::Client.new(
          :host => [options[:host], options[:port]].join(":")
        )

        return client
      end

      def bulk(actions)
        @client.bulk(:body => actions.collect do |action, args, source|
          if source
            next [ { action => args }, source ]
          else
            next { action => args }
          end
        end.flatten)
      end # def bulk

      public(:bulk)
    end

    class NodeClient < Base
      private

      DEFAULT_OPTIONS = {
        :port => 9300,
      }

      def initialize(options={})
        super
        require "java"
        @options = DEFAULT_OPTIONS.merge(options)
        setup(@options)
        @client = client
      end # def initialize
      
      def settings
        return @settings
      end

      def setup(options={})
        @settings = org.elasticsearch.common.settings.ImmutableSettings.settingsBuilder
        if options[:host]
          @settings.put("discovery.zen.ping.multicast.enabled", false)
          @settings.put("discovery.zen.ping.unicast.hosts", hosts(options))
        end

        @settings.put("node.client", true)
        @settings.put("http.enabled", false)
        
        if options[:client_settings]
          options[:client_settings].each do |key, value|
            @settings.put(key, value)
          end
        end

        return @settings
      end

      def hosts(options)
        if options[:port].to_s =~ /^\d+-\d+$/
          # port ranges are 'host[port1-port2]' according to 
          # http://www.elasticsearch.org/guide/reference/modules/discovery/zen/
          # However, it seems to only query the first port.
          # So generate our own list of unicast hosts to scan.
          range = Range.new(*options[:port].split("-"))
          return range.collect { |p| "#{options[:host]}:#{p}" }.join(",")
        else
          return "#{options[:host]}:#{options[:port]}"
        end
      end # def hosts

      def build_client(options)
        nodebuilder = org.elasticsearch.node.NodeBuilder.nodeBuilder
        return nodebuilder.settings(@settings).node.client
      end # def build_client

      def bulk(actions)
        # Actions an array of [ action, action_metadata, source ]
        prep = @client.prepareBulk
        actions.each do |action, args, source|
          prep.add(build_request(action, args, source))
        end
        response = prep.execute.actionGet()

        # TODO(sissel): What format should the response be in?
      end # def bulk

      def build_request(action, args, source)
        case action
          when "index"
            request = org.elasticsearch.action.index.IndexRequest.new(args[:_index])
            request.id(args[:_id]) if args[:_id]
            request.source(source)
          when "delete"
            request = org.elasticsearch.action.delete.DeleteRequest.new(args[:_index])
            request.id(args[:_id])
          #when "update"
          #when "create"
        end # case action

        request.type(args[:_type]) if args[:_type]
        return request
      end # def build_request

      public(:initialize, :bulk)
    end # class NodeClient

    class TransportClient < NodeClient
      private
      def build_client(options)
        client = org.elasticsearch.client.transport.TransportClient.new(settings.build)

        if options[:host]
          client.addTransportAddress(
            org.elasticsearch.common.transport.InetSocketTransportAddress.new(
              options[:host], options[:port]
            )
          )
        end

        return client
      end # def build_client
    end # class TransportClient
  end # module Protocols

  module Requests
    class GetIndexTemplates; end
    class Bulk; end
    class Index; end
    class Delete; end
  end
end

