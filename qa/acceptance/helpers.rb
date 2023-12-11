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

require 'net/http'
require 'json'

ARTIFACTS_API = "https://artifacts-api.elastic.co/v1/versions"

def logstash_download_metadata(version, arch, artifact_type)
  filename = "logstash-#{version}-#{arch}.#{artifact_type}"
  return { url: "https://artifacts.elastic.co/downloads/logstash/#{filename}", dest: File.join(ROOT, 'qa', filename) }
end

def fetch_latest_logstash_release_version(branch)
  uri = URI(ARTIFACTS_API)

  response = retryable_http_get(uri)
  versions_data = JSON.parse(response)

  filtered_versions = versions_data["versions"].select { |v| v.start_with?(branch) }

  return filtered_versions.max_by { |v| Gem::Version.new(v) }
end

def retryable_http_get(uri, max_retries=5, retry_wait=10)
  count = 0

  begin
    response = Net::HTTP.get(uri)
  rescue StandardError => e
    count += 1
    if count < max_retries
      puts "Retry attempt #{count}/#{max_retries}: #{e.message}"
      sleep(retry_wait)
      retry
    else
      puts "Exhausted all attempts trying to get from #{uri}."
      raise e
    end
  end
end
