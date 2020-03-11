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
      class Stats < ::LogStash::Api::Modules::Base
        def stats_command
          factory.build(:stats)
        end

        # return hot threads information
        get "/jvm/hot_threads" do
          begin
            top_threads_count = params["threads"] || 10
            ignore_idle_threads = params["ignore_idle_threads"] || true
            options = {
              :threads => top_threads_count.to_i,
              :ignore_idle_threads => as_boolean(ignore_idle_threads)
            }

            respond_with(stats_command.hot_threads(options))
          rescue ArgumentError => e
            response = respond_with({"error" => e.message})
            status(400)
            response
          end
        end

        # return hot threads information
        get "/jvm/memory" do
          respond_with({ :memory => stats_command.memory })
        end

        get "/?:filter?" do
          payload = {
            :events => stats_command.events,
            :jvm => {
              :timestamp => stats_command.started_at,
              :uptime_in_millis => stats_command.uptime,
              :memory => stats_command.memory,
            },
            :os => stats_command.os
          }
          respond_with(payload, {:filter => params["filter"]})
        end
      end
    end
  end
end
