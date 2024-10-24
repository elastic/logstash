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
  class PipelineResourceUsageValidator
    include LogStash::Util::Loggable

    WARN_HEAP_THRESHOLD = 10 # 10%

    def initialize(max_heap_size)
      @max_heap_size = max_heap_size
    end

    def check(pipelines_registry)
      return if pipelines_registry.size == 0

      percentage_of_heap = compute_percentage(pipelines_registry)

      if percentage_of_heap >= WARN_HEAP_THRESHOLD
        logger.warn("For a baseline of 2KB events, the maximum heap memory consumed across #{pipelines_registry.size} pipelines may reach up to #{percentage_of_heap}% of the entire heap (more if the events are bigger). The recommended percentage is less than #{WARN_HEAP_THRESHOLD}%. Consider reducing the number of pipelines, or the batch size and worker count per pipeline.")
      else
        logger.debug("For a baseline of 2KB events, the maximum heap memory consumed across #{pipelines_registry.size} pipelines may reach up to #{percentage_of_heap}% of the entire heap (more if the events are bigger).")
      end
    end

    def compute_percentage(pipelines_registry)
      max_event_count = sum_event_count(pipelines_registry)
      estimated_heap_usage = max_event_count * 2.0 * 1024 # assume 2KB per event
      percentage_of_heap = ((estimated_heap_usage / @max_heap_size) * 100).round(2)
    end

    def sum_event_count(pipelines_registry)
      pipelines_registry.loaded_pipelines.inject(0) do |sum, (pipeline_id, pipeline)|
        batch_size = pipeline.settings.get("pipeline.batch.size")
        pipeline_workers = pipeline.settings.get("pipeline.workers")
        sum + (batch_size * pipeline_workers)
      end
    end
  end
end
