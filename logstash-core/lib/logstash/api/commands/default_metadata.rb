# encoding: utf-8

require "logstash/api/commands/base"

module LogStash
  module Api
    module Commands
      class DefaultMetadata < Commands::Base
        def all
          {:host => host, :version => version, :http_address => http_address,
           :id => service.agent.id, :name => service.agent.name}
        end

        def host
          Socket.gethostname
        end

        def version
          LOGSTASH_CORE_VERSION
        end

        def http_address
          service.agent.webserver.address
        end
      end
    end
  end
end
