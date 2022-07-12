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

# The version of logstash core plugin api gem.
#
# sourced from a copy of the main versions.yml file, see logstash-core/logstash-core.gemspec
if !defined?(ALL_VERSIONS)
  require 'yaml'
  ALL_VERSIONS = YAML.load_file(File.expand_path("../../versions-gem-copy.yml", File.dirname(__FILE__)))
end

unless defined?(LOGSTASH_CORE_PLUGIN_API)
  LOGSTASH_CORE_PLUGIN_API = ALL_VERSIONS.fetch("logstash-core-plugin-api")
end

unless defined?(LOGSTASH_CORE_VERSION)
  LOGSTASH_CORE_VERSION = ALL_VERSIONS.fetch("logstash-core")
end
