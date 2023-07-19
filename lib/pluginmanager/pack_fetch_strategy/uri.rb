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

require "pluginmanager/utils/http_client"
require "pluginmanager/pack_installer/local"
require "pluginmanager/pack_installer/remote"
require "pluginmanager/ui"
require "net/http"
require "uri"

module LogStash module PluginManager module PackFetchStrategy
  class Uri
    class << self
      def get_installer_for(plugin_name)
        begin
          uri = URI.parse(plugin_name)

          if local?(uri)
            PluginManager.ui.debug("Local file: #{uri.path}")
            return LogStash::PluginManager::PackInstaller::Local.new(uri.path)
          elsif http?(uri)
            PluginManager.ui.debug("Remote file: #{uri}")
            return LogStash::PluginManager::PackInstaller::Remote.new(uri)
          else
            return nil
          end
        rescue URI::InvalidURIError,
          URI::InvalidComponentError,
          URI::BadURIError => e

          PluginManager.ui.debug("Invalid URI for pack, uri: #{uri}")
          return nil
        end
      end

      private
      def http?(uri)
        !uri.scheme.nil? && uri.scheme.match(/^http/)
      end

      def local?(uri)
        !uri.scheme.nil? && uri.scheme == "file"
      end
    end
  end
end end end
