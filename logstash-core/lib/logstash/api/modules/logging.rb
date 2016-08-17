# encoding: utf-8
module LogStash
  module Api
    module Modules
      class Logging < ::LogStash::Api::Modules::Base

        put "/" do
          level = params["log.level"]
          path = params["module"] || ""
          if level.nil?
            status 400
            respond_with({"error" => "[log.level] must be specified"})
          else
            LogStash::Logging::Logger::configure_logging(level, path)
            respond_with({"acknowledged" => true})
          end
        end

      end
    end
  end
end
