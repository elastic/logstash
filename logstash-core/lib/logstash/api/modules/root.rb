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

require 'timeout'

module LogStash
  module Api
    module Modules
      class Root < ::LogStash::Api::Modules::Base

        HEALTH_STATUS = [
          Java::OrgLogstashHealth::Status::GREEN,
          Java::OrgLogstashHealth::Status::YELLOW,
          Java::OrgLogstashHealth::Status::RED
        ].map(&:external_value)

        INVALID_HEALTH_STATUS_MESSAGE = "Invalid status '%s' provided. The valid statuses are: green, yellow, red."
        INVALID_TIMEOUT_MESSAGE = "Invalid timeout '%s' provided."
        TIMED_OUT_WAITING_FOR_STATUS_MESSAGE = "Timed out waiting for status '%s'."

        get "/" do
          input_status = params[:wait_for_status]
          input_timeout = params[:timeout]

          if input_status
            return status_error_response(input_status) unless target_status = parse_status(input_status)
          end

          if input_timeout
            return timeout_error_response(input_timeout) unless timeout_f = parse_timeout_f(input_timeout)
          end

          if target_status && timeout_f
            wait_for_status_and_respond(target_status, timeout_f)
          else
            command = factory.build(:system_basic_info)
            respond_with(command.run)
          end
        end

        private
        def parse_timeout_f(timeout)
          LogStash::Util::TimeValue.from_value(timeout).to_nanos/1e9
        rescue ArgumentError
        end

        def parse_status(target_status)
          target_status = target_status&.downcase
          target_status if HEALTH_STATUS.include?(target_status)
        end

        def timeout_error_response(timeout)
          respond_with(BadRequest.new(INVALID_TIMEOUT_MESSAGE % [timeout]))
        end

        def status_error_response(target_status)
          respond_with(BadRequest.new(INVALID_HEALTH_STATUS_MESSAGE % [target_status]))
        end

        def wait_for_status_and_respond(target_status, timeout)
          wait_interval_s = 1

          Timeout.timeout(timeout) do
            loop do
              current_status = HEALTH_STATUS.index(agent.health_observer.status.external_value)
              break if current_status <= HEALTH_STATUS.index(target_status)

              sleep(wait_interval_s)
              wait_interval_s = wait_interval_s * 2
            end

            command = factory.build(:system_basic_info)
            respond_with(command.run)
          end
        rescue Timeout::Error
          respond_with(TimedOut.new(TIMED_OUT_WAITING_FOR_STATUS_MESSAGE % [target_status]))
        end
      end
    end
  end
end
