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

require "pluginmanager/pack_installer/local"
require "pluginmanager/utils/downloader"
require "fileutils"

module LogStash module PluginManager module PackInstaller
  class Remote
    attr_reader :remote_url, :feedback

    def initialize(remote_url, feedback = Utils::Downloader::ProgressbarFeedback)
      @remote_url = remote_url
      @feedback = feedback
    end

    def execute
      PluginManager.ui.info("Downloading file: #{remote_url}")
      downloaded_file = Utils::Downloader.fetch(remote_url, feedback)
      PluginManager.ui.debug("Downloaded package to: #{downloaded_file}")

      PackInstaller::Local.new(downloaded_file).execute
    ensure
      FileUtils.rm_rf(downloaded_file) if downloaded_file
    end
  end
end end end
