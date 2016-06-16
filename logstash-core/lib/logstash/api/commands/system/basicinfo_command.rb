# encoding: utf-8
require 'logstash/api/commands/base'
require "logstash/util/duration_formatter"

module LogStash
  module Api
    module Commands
      module System
        class BasicInfo < Commands::Base

          def run
	    {} # Just return the defaults
          end
        end
      end
    end
  end
end
