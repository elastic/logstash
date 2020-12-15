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

# for backward compatibility
# logstash-devutils-1.3.6 logstash_helpers has dependency on this class
module LogStash
  class Pipeline

    # for backward compatibility in devutils for the logstash helpers, this method is not used
    # in the pipeline anymore.
    def initialize(pipeline_config, namespaced_metric = nil, agent = nil)
    end
    #
    # for backward compatibility in devutils for the rspec helpers, this method is not used
    # in the pipeline anymore.
    def filter(event, &block)
    end

    # for backward compatibility in devutils for the rspec helpers, this method is not used
    # in the pipeline anymore.
    def flush_filters(options = {}, &block)
    end
  end
end