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

require "bootstrap/util/compress"
require "fileutils"

class LogStash::PluginManager::PackCommand < LogStash::PluginManager::Command
  def archive_manager
    zip? ? LogStash::Util::Zip : LogStash::Util::Tar
  end

  def file_extension
    zip? ? ".zip" : ".tar.gz"
  end

  def signal_deprecation_warning_for_pack
  message = <<-EOS
The pack and the unpack command are now deprecated and will be removed in a future version of Logstash.
See the `prepare-offline-pack` to update your workflow. You can get documentation about this by running `bin/logstash-plugin prepare-offline-pack --help`
  EOS
  puts message
  end
end
