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

module LogStash
  module Api
    module Modules
      class Root < ::LogStash::Api::Modules::Base

        HEALTH_STATUS = [
          Java::OrgLogstashHealth::Status::GREEN.to_s,
          Java::OrgLogstashHealth::Status::YELLOW.to_s,
          Java::OrgLogstashHealth::Status::RED.to_s
        ]

        get "/" do
          target_status = params[:wait_for_status]&.upcase

          if target_status && HEALTH_STATUS.include?(target_status)
            wait_for_status(params[:timeout], target_status) if params[:timeout]
          end

          command = factory.build(:system_basic_info)
          respond_with command.run
        end

        private
        def wait_for_status(timeout, target_status)
          end_time = Time.now + timeout.to_i
          wait_interval_seconds = 1

          while Time.now < end_time
            break if target_status == agent.health_observer.status.to_s
            sleep(wait_interval_seconds)
            wait_interval_seconds = wait_interval_seconds * 2
          end
        end
      end
    end
  end
end
