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
      class NodeStats < ::LogStash::Api::Modules::Base

        before do
          @stats = factory.build(:stats)
        end

        get "/pipelines/:id?" do
          payload = pipeline_payload(params["id"])
          halt(404) if payload.empty?
          respond_with(:pipelines => payload)
        end

        get "/?:filter?" do
          payload = {
            :jvm => jvm_payload,
            :process => process_payload,
            :events => events_payload,
            :flow => flow_payload,
            :pipelines => pipeline_payload,
            :reloads => reloads_payload,
            :os => os_payload,
            :queue => queue
          }

          geoip = geoip_payload
          payload[:geoip_download_manager] = geoip unless geoip.empty? || geoip[:download_stats][:status].value.nil?

          respond_with(payload, {:filter => params["filter"]})
        end

        private
        def queue
          @stats.queue
        end

        private
        def os_payload
          @stats.os
        end

        def events_payload
          @stats.events
        end

        def flow_payload
          @stats.flow
        end

        def jvm_payload
          @stats.jvm
        end

        def reloads_payload
          @stats.reloads
        end

        def process_payload
          @stats.process
        end

        def pipeline_payload(val = nil)
          opts = {:vertices => as_boolean(params.fetch("vertices", false))}
          @stats.pipeline(val, opts)
        end

        def geoip_payload
          @stats.geoip
        end

      end
    end
  end
end
