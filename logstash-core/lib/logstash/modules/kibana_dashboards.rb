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

require_relative "kibana_base"

module LogStash module Modules class KibanaDashboards < KibanaBase
  include LogStash::Util::Loggable

  attr_reader :import_path, :content

  # content is a list of kibana file resources
  def initialize(import_path, content)
    @import_path, @content = import_path, content
  end

  def import(client)
    # e.g. curl "http://localhost:5601/api/kibana/dashboards/import"
    # extract and prepare all objects
    objects = []
    content.each do |resource|
      hash = {
        "id" => resource.content_id,
        "type" => resource.content_type,
        "version" => 1,
        "attributes" => resource.content_as_object
      }
      objects << hash
    end
    body = {"version": client.version, "objects": objects}
    response = client.post(import_path, body)
    if response.failed?
      logger.error("Attempted POST failed", :url_path => import_path, :response => response.body)
    end
    response
  end
end end end
