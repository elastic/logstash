# encoding: utf-8
require 'logstash/api/commands/base'
require "logstash/util/duration_formatter"

module LogStash
  module Api
    module Commands
      module System
        class BasicInfo < Commands::Base

          def run
            {
              "hostname" => hostname,
              "version" => {
                "number" => LOGSTASH_VERSION
              }
            }
          end
        end
      end
    end
  end
end
