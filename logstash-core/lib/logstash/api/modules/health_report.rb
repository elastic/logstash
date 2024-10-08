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
      class HealthReport < ::LogStash::Api::Modules::Base

        get "/" do
          payload = health_report.all.then do |health_report_pojo|
            # The app_helper needs a ruby-hash.
            # Manually creating a map of properties works around the issue.
            base_metadata.merge({
              status:     health_report_pojo.status,
              symptom:    health_report_pojo.symptom,
              indicators: health_report_pojo.indicators,
            })
          end

          respond_with(payload, {exclude_default_metadata: true})
        end

        private

        def health_report
          @health_report ||= factory.build(:health_report)
        end

        def base_metadata
          @factory.build(:default_metadata).base_info
        end
      end
    end
  end
end