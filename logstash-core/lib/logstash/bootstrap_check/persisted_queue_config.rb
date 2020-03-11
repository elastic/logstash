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
  module BootstrapCheck
    class PersistedQueueConfig
      def self.check(settings)
        return unless settings.get('queue.type') == 'persisted'
        if settings.get('queue.page_capacity') > settings.get('queue.max_bytes')
          raise(LogStash::BootstrapCheckError, I18n.t("logstash.bootstrap_check.persisted_queue_config.page-capacity"))
        end
      end
    end
  end
end
