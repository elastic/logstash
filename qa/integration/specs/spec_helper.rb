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

def es_allow_wildcard_deletes(es_client)
  es_client.cluster.put_settings body: { transient: { 'action.destructive_requires_name' => false } }
end

def clean_es(es_client)
  es_client.indices.delete_template(:name => "*") rescue nil
  es_client.indices.delete_index_template(:name => "*") rescue nil
  es_client.indices.delete(:index => "*")
  es_client.indices.refresh
end

def serverless?
  ENV["SERVERLESS"] == "true"
end

RSpec.configure do |config|
  if RbConfig::CONFIG["host_os"] != "linux"
    exclude_tags = { :linux => true }
  end

  config.filter_run_excluding exclude_tags
end

RSpec::Matchers.define :have_hits do |expected|
  match do |actual|
    return false if actual.nil? || actual['hits'].nil?
    # For Elasticsearch versions 7+, the result is in a value field, just in total for > 6
    if actual['hits']['total'].is_a?(Hash)
      expected == actual['hits']['total']['value']
    else
      expected == actual['hits']['total']
    end
  end
end
