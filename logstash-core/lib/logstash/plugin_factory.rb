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

class LogStash::PluginFactory
  module ExecutionContextInitializer
    refine LogStash::Plugin do
      def initialize(*args,&block)
        @execution_context = Thread.current.thread_variable_get(:plugin_execution_context)
        super
      end
    end
  end

  def initialize(execution_context, plugin_registry=LogStash::PLUGIN_REGISTRY)
    @execution_context = execution_context
    @plugin_registry = plugin_registry
    freeze
  end

  %w(
    input
    output
    filter
    codec
  ).each do |plugin_type|
    define_method("new_#{plugin_type}") do |name, *args, &block|
      plugin_klass = @plugin_registry.lookup_pipeline_plugin(type, name)
      init(plugin_klass, *args, &block)
    end
  end

  using ExecutionContextInitializer

  def init(plugin_klass, *args, &block)
    previous_execution_context = Thread.current.thread_variable_get(:plugin_execution_context)
    Thread.current.thread_variable_set(:plugin_execution_context, @execution_context)

    return plugin_klass.new(*args, &block)

  ensure
    Thread.current.thread_variable_set(:plugin_execution_context, previous_execution_context)
  end
end