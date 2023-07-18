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

require "logstash/api/service"
require "logstash/api/commands/system/basicinfo_command"
require "logstash/api/commands/system/plugins_command"
require "logstash/api/commands/stats"
require "logstash/api/commands/node"
require "logstash/api/commands/default_metadata"

module LogStash
  module Api
    class CommandFactory
      attr_reader :factory, :service

      def initialize(service)
        @service = service
        @factory = {
          :system_basic_info => ::LogStash::Api::Commands::System::BasicInfo,
          :plugins_command => ::LogStash::Api::Commands::System::Plugins,
          :stats => ::LogStash::Api::Commands::Stats,
          :node => ::LogStash::Api::Commands::Node,
          :default_metadata => ::LogStash::Api::Commands::DefaultMetadata
        }
      end

      def build(*klass_path)
        # Get a nested path with args like (:parent, :child)
        klass = klass_path.reduce(factory) {|acc, v| acc[v]}

        if klass
          klass.new(service)
        else
          raise ArgumentError, "Class path '#{klass_path}' does not map to command!"
        end
      end
    end
  end
end
