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

# I've decided to take the action strategy, I think this make the code a bit easier to understand.
# maybe in the context of config management we will want to have force kill on the
# threads instead of waiting forever or sending feedback to the host
#
# Some actions could be retryable, or have a delay or timeout.
module LogStash module PipelineAction
  class Base
    # Only used for debugging purpose and in the logger statement.
    def inspect
      "#{self.class.name}/pipeline_id:#{pipeline_id}"
    end
    alias_method :to_s, :inspect

    def execute(agent, pipelines_registry)
      raise "`#execute` Not implemented!"
    end

    # See the definition in `logstash/pipeline_action.rb` for the default ordering
    def execution_priority
      ORDERING.fetch(self.class)
    end

    def <=>(other)
      order = self.execution_priority <=> other.execution_priority
      order.nonzero? ? order : self.pipeline_id <=> other.pipeline_id
    end
  end
end end
