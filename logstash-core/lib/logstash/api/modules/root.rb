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

        get "/" do
          target_status = params[:wait_for_status]&.downcase
          timeout = params[:timeout].to_i
          status = 200

          if HEALTH_STATUS.include?(target_status) && timeout > 0
            begin
              wait_for_status(params[:timeout], target_status)
            rescue Timeout::Error
              status = 503
            end
          end

          command = factory.build(:system_basic_info)
          respond_with(command.run, status_code: status)
        end

        private
        def wait_for_status(timeout_seconds, target_status)
          wait_interval_seconds = 1

          Timeout.timeout(timeout_seconds.to_i) do
            current_status = HEALTH_STATUS.index(agent.health_observer.status.external_value)
            break if current_status <= HEALTH_STATUS.index(target_status)

            sleep(wait_interval_seconds)
            wait_interval_seconds = wait_interval_seconds * 2
          end
        end
      end
    end
  end
end
