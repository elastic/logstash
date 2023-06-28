# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

java_import org.apache.logging.log4j.core.LoggerContext
java_import java.lang.IllegalArgumentException

module LogStash
  module Api
    module Modules
      class Logging < ::LogStash::Api::Modules::Base
        # retrieve logging specific parameters from the provided settings
        #
        # return any unused configurations
        def handle_logging(settings)
          couplesList = settings.map do |key, level|
            if key.start_with?("logger.")
              _, path = key.split("logger.")
              LogStash::Logging::Logger::configure_logging(level, path)
              nil
            else
              [key, level]
            end
          end.reject {|value| value.nil?} # skip nil which result in ArgumentError since JRuby 9.4
          Hash[couplesList]
        end

        put "/" do
          begin
            request.body.rewind
            req_body = LogStash::Json.load(request.body.read)
            remaining = handle_logging(req_body)
            unless remaining.empty?
              raise ArgumentError, I18n.t("logstash.web_api.logging.unrecognized_option", :option => remaining.keys.first)
            end
            respond_with({"acknowledged" => true})
          rescue IllegalArgumentException => e
            status 400
            respond_with({"error" => e.message})
          rescue ArgumentError => e
            status 400
            respond_with({"error" => e.message})
          end
        end

        put "/reset" do
          context = LogStash::Logging::Logger::get_logging_context
          if context.nil?
            status 500
            respond_with({"error" => "Logstash loggers were not initialized properly"})
          else
            context.reconfigure
            respond_with({"acknowledged" => true})
          end
        end

        get "/" do
          context = LogStash::Logging::Logger::get_logging_context
          if context.nil?
            status 500
            respond_with({"error" => "Logstash loggers were not initialized properly"})
          else
            loggers = context.getLoggers.map { |lgr| [lgr.getName, lgr.getLevel.name] }.sort
            respond_with({"loggers" => Hash[loggers]})
          end
        end
      end
    end
  end
end
