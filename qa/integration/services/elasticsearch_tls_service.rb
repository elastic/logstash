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

require 'elasticsearch'

class ElasticsearchTlsService < Service
  def initialize(settings)
    super("elasticsearch_tls", settings)
    # Reuse elasticsearch_setup/teardown.sh; TLS mode is activated when
    # ES_TLS_CERT env var is set (done in spec before(:all)).
    @setup_script    = File.expand_path("../elasticsearch_setup.sh",    __FILE__)
    @teardown_script = File.expand_path("../elasticsearch_teardown.sh", __FILE__)
  end

  def get_client
    @client ||= Elasticsearch::Client.new(
      hosts: ["https://localhost:9200"],
      user: "esadmin",
      password: "esadmin123",
      transport_options: { ssl: { verify: false } }
    )
  end
end
