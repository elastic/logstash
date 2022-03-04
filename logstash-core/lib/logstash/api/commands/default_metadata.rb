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

require "logstash/api/commands/base"

module LogStash
  module Api
    module Commands
      class DefaultMetadata < Commands::Base
        def all
          res = {:host => host,
             :version => version,
             :http_address => http_address,
             :id => service.agent.id,
             :name => service.agent.name,
             :ephemeral_id => service.agent.ephemeral_id,
             :status => "green",  # This is hard-coded to mirror x-pack behavior
             :snapshot => ::BUILD_INFO["build_snapshot"],
             :pipeline => {
               :workers => LogStash::SETTINGS.get("pipeline.workers"),
               :batch_size => LogStash::SETTINGS.get("pipeline.batch.size"),
               :batch_delay => LogStash::SETTINGS.get("pipeline.batch.delay"),
             },
            }
          monitoring = {}
          if enabled_xpack_monitoring?
            monitoring = monitoring.merge({
                        :hosts => LogStash::SETTINGS.get("xpack.monitoring.elasticsearch.hosts"),
                        :username => LogStash::SETTINGS.get("xpack.monitoring.elasticsearch.username")
                        })
          end
          if LogStash::SETTINGS.set?("monitoring.cluster_uuid")
            monitoring = monitoring.merge({:cluster_uuid => LogStash::SETTINGS.get("monitoring.cluster_uuid")})
          end
          res.merge(monitoring.empty? ? {} : {:monitoring => monitoring})
        end

        def host
          @@host ||= Socket.gethostname
        end

        def version
          LOGSTASH_CORE_VERSION
        end

        def http_address
          @http_address ||= service.get_shallow(:http_address).value
        rescue ::LogStash::Instrument::MetricStore::MetricNotFound, NoMethodError => e
          nil
        end

        private
        def enabled_xpack_monitoring?
          LogStash::SETTINGS.registered?("xpack.monitoring.enabled") &&
          LogStash::SETTINGS.get("xpack.monitoring.enabled")
        end
      end
    end
  end
end
