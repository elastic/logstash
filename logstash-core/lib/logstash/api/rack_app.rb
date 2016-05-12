require "logstash/api/modules/base"
require "logstash/api/modules/node"
require "logstash/api/modules/node_stats"
require "logstash/api/modules/plugins"
require "logstash/api/modules/root"
require "logstash/api/modules/stats"

module LogStash
  module Api
    module RackApp
      def self.app
        namespaces = rack_namespaces 
        Rack::Builder.new do
          run LogStash::Api::Modules::Root
          namespaces.each_pair do |namespace, app|
            map(namespace) do
              run app
            end
          end
        end
      end

      def self.rack_namespaces
        {
          "/_node" => LogStash::Api::Modules::Node,
          "/_stats" => LogStash::Api::Modules::Stats,
          "/_node/stats" => LogStash::Api::Modules::NodeStats,
          "/_plugins" => LogStash::Api::Modules::Plugins
        }
      end
    end
  end
end
