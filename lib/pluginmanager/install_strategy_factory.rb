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

require "pluginmanager/ui"
require "pluginmanager/x_pack_interceptor"
require "pluginmanager/pack_fetch_strategy/repository"
require "pluginmanager/pack_fetch_strategy/uri"

module LogStash module PluginManager
  class InstallStrategyFactory
    AVAILABLES_STRATEGIES = [
      LogStash::PluginManager::PackFetchStrategy::Uri,
      LogStash::PluginManager::PackFetchStrategy::Repository
    ]

    def self.create(plugins_args)
      plugin_name_or_uri = plugins_args.first
      return false if plugin_name_or_uri.nil? || plugin_name_or_uri.strip.empty?

      # if the user is attempting to install X-Pack, present helpful output to guide
      # them toward the default distribution of Logstash
      XPackInterceptor::Install.intercept!(plugin_name_or_uri)

      AVAILABLES_STRATEGIES.each do |strategy|
        if installer = strategy.get_installer_for(plugin_name_or_uri)
          return installer
        end
      end
      return false
    end
  end
end end
